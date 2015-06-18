/*
  For parsing [PROV-N](http://www.w3.org/TR/prov-n/) notation
*/

document =
    _ 'document'
    _ namespaces:(namespaceDeclarations)? 
    _ expressions:expression*
    _ bundles:bundle*
    _ 'endDocument' _;

bundle = 'bundle'
    _ bundle:identifier
    _ namespaces:namespaceDeclarations?
    _ expressions:expression*
    _ 'endBundle' _;

// NOTE: because this is a PEG, there is some potential for optimization by
//       placing the more common expressions first in the choice list
expression = _:(
    activityExpression /
    agentExpression /
    entityExpression /
    generationExpression /
    usageExpression /
    startExpression /
    endExpression /
    invalidationExpression /
    communicationExpression /
    associationExpression /
    attributionExpression /
    delegationExpression /
    derivationExpression /
    influenceExpression /
    alternateExpression /
    specializationExpression /
    membershipExpression /
    extensibilityExpression
    ) _


/*
   Expressions
*/

activityExpression =
    expressionType:'activity' '('
    activity:identifier
    ( CMMA timeOrMarker CMMA timeOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

agentExpression =
    expressionType:'agent' '('
    agent:identifier
    attributeValuePairs:optionalAttributeValuePairs? ')';

entityExpression =
    expressionType:'entity' '('
    entity:identifier
    attributeValuePairs:optionalAttributeValuePairs? ')';

generationExpression =
    expressionType:'wasGeneratedBy' '('
    optionalIdentifier:optionalIdentifier?
    entity:identifier
    wasGeneratedBy:( CMMA activity:identifierOrMarker CMMA time:timeOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

usageExpression =
    expressionType:'used' '('
    optionalIdentifier:optionalIdentifier?
    activity:identifier
    used:( CMMA entity:identifierOrMarker CMMA time:timeOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

startExpression =
    expressionType:'wasStartedBy' '('
    optionalIdentifier:optionalIdentifier?
    agent:identifier
    wasStartedBy:( CMMA entity:identifierOrMarker CMMA agent:identifierOrMarker CMMA time:timeOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

endExpression =
    expressionType:'wasEndedBy' '('
    optionalIdentifier:optionalIdentifier?
    agent:identifier
    wasEndedBy:( CMMA entity:identifierOrMarker CMMA agent:identifierOrMarker CMMA time:timeOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

invalidationExpression =
    expressionType:'wasInvalidatedBy' '('
    optionalIdentifier:optionalIdentifier?
    entity:identifier
    wasInvalidatedBy:( CMMA agent:identifierOrMarker CMMA time:timeOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

communicationExpression =
    expressionType:'wasInformedBy' '('
    optionalIdentifier:optionalIdentifier?
    agent:identifier CMMA
    wasInformedBy:identifier
    attributeValuePairs:optionalAttributeValuePairs? ')';

associationExpression =
    expressionType:'wasAssociatedWith' '('
    optionalIdentifier:optionalIdentifier?
    agent:identifier
    wasAssociatedWith:( CMMA agent:identifierOrMarker CMMA entity:identifierOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

attributionExpression =
    expressionType:'wasAttributedTo' '('
    optionalIdentifier:optionalIdentifier?
    entity:identifier CMMA
    wasAttributedTo:identifier
    attributeValuePairs:optionalAttributeValuePairs? ')';

delegationExpression =
    expressionType:'actedOnBehalfOf' '('
    optionalIdentifier:optionalIdentifier?
    agent:identifier CMMA
    actedOnBehalfOf:identifier
    activity:( CMMA _:identifierOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

derivationExpression =
    expressionType:'wasDerivedFrom' '('
    optionalIdentifier:optionalIdentifier?
    entity:identifier CMMA
    wasDerivedFrom:identifier
    ( CMMA activity:identifierOrMarker CMMA generation:identifierOrMarker CMMA usage:identifierOrMarker )?
    attributeValuePairs:optionalAttributeValuePairs? ')';

influenceExpression =
    expressionType:'wasInfluencedBy' '('
    optionalIdentifier:optionalIdentifier?
    entity:identifier CMMA
    wasDerivedFrom:identifier
    attributeValuePairs:optionalAttributeValuePairs? ')';

alternateExpression =
    expressionType:'alternateOf' '('
    entity:identifier CMMA
    alternateOf:identifier ')';

specializationExpression =
    expressionType:'specializationOf' '('
    entity:identifier CMMA
    specializationOf:identifier ')';

membershipExpression =
    expressionType:'hadMember' '('
    collection:identifier CMMA
    hadMember:identifier ')';

extensibilityExpression = extName:QUALIFIED_NAME
    expressionType:'('
    optionalIdentifier:optionalIdentifier?
    extargs:(_:extensibilityArgument ( CMMA &extensibilityArgument / &optionalAttributeValuePairs ) )*
    attributeValuePairs:optionalAttributeValuePairs? ')';

extensibilityArgument = ( identifierOrMarker / literal / time / extensibilityExpression / extensibilityTuple );

extensibilityTuple =
      '{' _:(_:extensibilityArgument ( CMMA &extensibilityArgument / &'}' ))+ '}'
    / '(' _:(_:extensibilityArgument ( CMMA &extensibilityArgument / &')' ))+ ')';


/*
   attributes/values/identifiers
*/

optionalAttributeValuePairs = CMMA '[' _ _:attributeValuePairs _ ']' _;

attributeValuePairs = ( _:attributeValuePair
                        _ ( CMMA &attributeValuePair / &(_ ']') ) )+;

attributeValuePair = attribute:attribute _ '=' _ value:literal;

timeOrMarker = ( time / '-' );

optionalIdentifier = _ _:identifierOrMarker _ ';' _;

identifierOrMarker = _ _:( identifier / '-' );

identifier = QUALIFIED_NAME;

attribute = QUALIFIED_NAME;

literal = typedLiteral / convenienceNotation;

typedLiteral = literal:STRING_LITERAL '%%' datatype:datatype;

datatype = QUALIFIED_NAME;

convenienceNotation = $(STRING_LITERAL (LANGTAG)? / INT_LITERAL / QUALIFIED_NAME_LITERAL);

time = DATETIME;

namespaceDeclarations = defaultNamespace:(defaultNamespaceDeclaration / !defaultNamespaceDeclaration) namespaces:namespaceDeclaration*;

namespaceDeclaration = 'prefix' _ prefix:PN_PREFIX  _ namespace:namespace;

defaultNamespaceDeclaration = 'default' _ IRI_REF;

namespace = IRI_REF ;

QUALIFIED_NAME = prefix:( _:PN_PREFIX ':' )? local:PN_LOCAL /  prefix:PN_PREFIX ':' local:!PN_LOCAL;


/*
   rules that are just about straight from the PROV-N specification (with some $() textualizations)
*/

PN_NON_DOT = PN_CHARS / PN_CHARS_OTHERS;

PN_LOCAL = $(( PN_CHARS_U / [0-9] / PN_CHARS_OTHERS ) (PN_NON_DOT / '.'+ &PN_NON_DOT)*);

PN_CHARS_OTHERS = [/@~&+*?#$!] / PERCENT / PN_CHARS_ESC;

PN_CHARS_ESC = '\\' [=\'(),\-:;\[\]\.];

PERCENT = '%' HEX HEX;

HEX = [0-9A-Fa-f];

STRING_LITERAL = STRING_LITERAL2 / STRING_LITERAL_LONG2;

PREFX = PN_PREFIX;

INT_LITERAL = ('-')? (DIGIT)+;

QUALIFIED_NAME_LITERAL = '\'' QUALIFIED_NAME '\'';

DIGIT = [0-9];

DATETIME = $(DIGIT DIGIT DIGIT DIGIT '-' DIGIT DIGIT '-' DIGIT DIGIT 'T' DIGIT DIGIT ':' DIGIT DIGIT ':' DIGIT DIGIT ( '.' DIGIT (( DIGIT (DIGIT)? )? ))? (( 'Z' / TIMEZONEOFFSET ))?);

TIMEZONEOFFSET = ( '+' / '-' ) DIGIT DIGIT ':' DIGIT DIGIT;


/*
   from SPARQL
*/

PN_CHARS_BASE = [A-Z] / [a-z] / [\u00C0-\u00D6] / [\u00D8-\u00F6] /
              [\u00F8-\u02FF] / [\u0370-\u037D] / [\u037F-\u1FFF] /
              [\u200C-\u200D] / [\u2070-\u218F] / [\u2C00-\u2FEF] /
              [\u3001-\uD7FF] / [\uF900-\uFDCF] / [\uFDF0-\uFFFD] ; // FIXME: the prov-n spec allows [\u10000-\uEFFFF], but javascript treats these characters weirdly
PN_CHARS_U = PN_CHARS_BASE / '_' ;
PN_PREFIX = $(PN_CHARS_BASE (PN_CHARS / '.'* PN_CHARS)*);
VARNAME = ( PN_CHARS_U / [0-9] ) ( PN_CHARS_U / [0-9] / [\u00B7\u0300-\u036f\u203f-\u2040] )* ;
PN_CHARS = PN_CHARS_U / '-' / [0-9] / [\u0300-\u036F] / [\u203F-\u2040];
STRING_LITERAL2 = DOUBLE_QUOTE ( ([^\u0022\u005C\u000A\u000D]) / ECHAR )* DOUBLE_QUOTE;
STRING_LITERAL_LONG2 = '"""' ( ( '"' / '""' )? ( [^"\\] / ECHAR ) )* '"""';
ECHAR = '\\' [tbnrf\'\"];
LANGTAG = '@' [a-zA-Z]+ ('-' [a-zA-Z0-9]+)*;
IRI_REF = ('<' ([^<>"{}|^`\u0000-\u0020] / '[' / '\\' / ']')* '>') { return text(); };


/*
   helpers
*/

comment = '//' [^\r\n]* [\r\n] /
    '/*' (!'*/' .)* '*/'

SINGLE_QUOTE = '\'';
DOUBLE_QUOTE = '"';
CMMA = _ ',' _; // Comma with whitespace permitted around it
_ = ([ \r\t\n] / comment)* { return undefined; }; // whitespace
