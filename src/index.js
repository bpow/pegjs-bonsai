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

    function generate_code_without_undefined(labels) {
        return ['\n  var val = {};']
            .concat(labels.map(function(label) {
                return '  if (' + label + ' !== undefined && ' + label + ' !== null) val["' + label + '"] = ' + label + ';';
            }))
            .concat('  return val;')
            .join('\n');
    }

    var generate_code = generate_code_without_undefined;

    function process_expression(exp, stack) {
        if ("action" !== stack[stack.length-1].type) {
            if ("sequence" === exp.type) {
                var stack_plus = stack.concat(exp);
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
                }
            } // sequence
            if ("choice" === exp.type) {
                var next_stack = stack.concat(exp);
                exp.alternatives = exp.alternatives.map(function (alt) {
                    return process_expression(alt, next_stack);
                });
            } // choice
        }
        if (exp.expression) {
            exp.expression = process_expression(exp.expression, stack.concat(exp));
        }
        return exp;
    }

    // Here is the actual body of the 'pass' function:
    myOptions = options.bonsaiPlugin ? options.bonsaiPlugin : {};
    if (myOptions.keepUndefined) {
        generate_code = function(labels) {
            return 'return {' + 
                labels.map(function(l) { return '"' + l + '":' + l; }).join(',') +
                    ' };';
        };
    }
    ast.rules = ast.rules.map(process_rule);
    if (myOptions.showTransformed) {
        console.log(JSON.stringify(ast.rules, null, 2));
    }
};

exports.use = function (config, options) {
    config.passes.transform.unshift(exports.pass);
};
