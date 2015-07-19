/*jslint node: true */
'use strict';

exports.pass = function(ast, options) {
    var myOptions = {};
    function process_rule(rule, index, arr) {
        rule.expression = process_expression(rule.expression, [rule]);
        return rule;
    }

    function arr_each(arr, callback) {
        var len = arr.length;
        for (var i = 0; i < len; i++) {
            callback(arr[i], i);
        }
        return arr;
    }

    function generate_code(labels) {
        return ['\n  var val = {};']
            .concat(labels.map(function(label) {
                var code = '  ';
                if (!myOptions.keepUndefined) {
                    code += 'if (' + label + ' !== undefined && ' + label + ' !== null) ';
                }
                code += 'val["' + label + '"] = ' + label + ';';
                return code;
            }))
            .concat('  return val;')
            .join('\n');
    }

    function process_expression(exp, stack) {
        var stack_plus = stack.concat(exp);
        if ("action" !== stack[stack.length-1].type) {
            if ("sequence" === exp.type) {
                var labels = [];
                exp.elements = exp.elements.map(function (e) {
                    if ("labeled" === e.type) labels.push(e.label);
                    return process_expression(e, stack_plus);
                });
                if (labels.length == 1 && labels[0] == '_') {
                    // special case to flatten if there is only one named element
                    exp = {
                        type: 'action',
                        code: 'return ' + labels[0] + ';',
                        expression: exp
                    };
                } else if (labels.length > 0) {
                    exp = {
                        type: 'action',
                        code: generate_code(labels),
                        expression: exp
                    };
                    stack_plus = stack.concat(exp);
                }
            } // sequence
        }
        if (exp.expression) {
            exp.expression = process_expression(exp.expression, stack.concat(exp));
        } else if (exp.alternatives) { // choice
            exp.alternatives = exp.alternatives.map(function (alt) {
                return process_expression(alt, stack_plus);
            });
        } else if (exp.elements) { // sequence 
            exp.elements = exp.elements.map(function (e) {
                return process_expression(e, stack_plus);
            });
        }
        return exp;
    }

    // Here is the actual body of the 'pass' function:
    myOptions = options.bonsaiPlugin ? options.bonsaiPlugin : {};
    ast.rules = ast.rules.map(process_rule);
    if (myOptions.showTransformed) {
        console.log(JSON.stringify(ast.rules, null, 2));
    }
};

exports.use = function (config, options) {
    config.passes.transform.unshift(exports.pass);
};
