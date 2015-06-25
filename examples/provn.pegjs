/*
  For parsing [PROV-N](http://www.w3.org/TR/prov-n/) notation
*/

document =
    _ 'document'
    _ namespaces:(namespaceDeclarations)?
    _ expressions:expression*
    _ bundles:bundle*
    _ 'endDocument' _;

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
   Component 1: Entites and Activities
*/

entityExpression =
    expressionType:'entity' '('
    id:identifier
    attributes:optionalattributes? ')';

activityExpression =
    expressionType:'activity' '('
    id:identifier
    optionals:( CMMA startTime:timeOrMarker CMMA endTime:timeOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

generationExpression =
    expressionType:'wasGeneratedBy' '('
    id:optionalIdentifier?
    entity:identifier
    optionals:( CMMA activity:identifierOrMarker CMMA time:timeOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

usageExpression =
    expressionType:'used' '('
    id:optionalIdentifier?
    activity:identifier
    optionals:( CMMA entity:identifierOrMarker CMMA time:timeOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

communicationExpression =
    expressionType:'wasInformedBy' '('
    id:optionalIdentifier?
    informed:identifier CMMA
    informant:identifier
    attributes:optionalAttributeValuePairs? ')';

startExpression =
    expressionType:'wasStartedBy' '('
    id:optionalIdentifier?
    activity:identifier
    optionals:( CMMA trigger:identifierOrMarker CMMA starter:identifierOrMarker CMMA time:timeOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

endExpression =
    expressionType:'wasEndedBy' '('
    id:optionalIdentifier?
    activity:identifier
    optionals:( CMMA trigger:identifierOrMarker CMMA ender:identifierOrMarker CMMA time:timeOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

invalidationExpression =
    expressionType:'wasInvalidatedBy' '('
    id:optionalIdentifier?
    entity:identifier
    optionals:( CMMA activity:identifierOrMarker CMMA time:timeOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

/*
   Component 2: Derivations
*/

derivationExpression =
    expressionType:'wasDerivedFrom' '('
    id:optionalIdentifier?
    generatedEntity:identifier CMMA
    usedEntity:identifier
    ( CMMA activity:identifierOrMarker CMMA generation:identifierOrMarker CMMA usage:identifierOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

/*
   Component 3: Agents, Responsibility and Influence
*/

agentExpression =
    expressionType:'agent' '('
    id:identifier
    attributes:optionalAttributeValuePairs? ')';

attributionExpression =
    expressionType:'wasAttributedTo' '('
    id:optionalIdentifier?
    entity:identifier CMMA
    agent:identifier
    attributes:optionalAttributeValuePairs? ')';

associationExpression =
    expressionType:'wasAssociatedWith' '('
    id:optionalIdentifier?
    activity:identifier
    optionals:( CMMA agent:identifierOrMarker CMMA plan:identifierOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

delegationExpression =
    expressionType:'actedOnBehalfOf' '('
    id:optionalIdentifier?
    delegate:identifier CMMA
    responsible:identifier
    activity:( CMMA _:identifierOrMarker )?
    attributes:optionalAttributeValuePairs? ')';

influenceExpression =
    expressionType:'wasInfluencedBy' '('
    id:optionalIdentifier?
    influencee:identifier CMMA
    influencer:identifier
    attributes:optionalAttributeValuePairs? ')';

/*
   Component 4: Bundles
*/

bundle = 'bundle'
    _ id:identifier
    _ namespaces:namespaceDeclarations?
    _ descriptions:expression*
    _ 'endBundle' _;

/*
   Component 5: Alternate Entities
*/

specializationExpression =
    expressionType:'specializationOf' '('
    specificEntity:identifier CMMA
    generalEntity:identifier ')';

alternateExpression =
    expressionType:'alternateOf' '('
    alternate1:identifier CMMA
    alternate2:identifier ')';

/*
   Component 6: Collections
*/

membershipExpression =
    expressionType:'hadMember' '('
    collection:identifier CMMA
    entity:identifier ')';

/*
   Extensibility
*/

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
   basic definitions (PEGs do not have lexing, but this section is pretty much lexical)
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
IRI_REF = $('<' ([^<>"{}|^`\u0000-\u0020] / '[' / '\\' / ']')* '>');


/*
   helpers
*/

comment = '//' [^\r\n]* [\r\n] /
    '/*' (!'*/' .)* '*/'

SINGLE_QUOTE = '\'';
DOUBLE_QUOTE = '"';
CMMA = _ ',' _; // Comma with whitespace permitted around it
_ = ([ \r\t\n] / comment)* { return undefined; }; // whitespace
