"use strict";

var PEG = require('pegjs');
var bonsai = require('../src/index.js');

describe("Bonsai", function () {

    it("creates a parser", function() {
        var parser = PEG.buildParser("word = $([a-zA-Z]+);", {plugins:[bonsai]});
        expect(typeof parser).toBe("object");
        expect(parser.parse).toBeDefined();
    });

    it("uses an existing action, when available", function () {
        var grammar = [
            'actor = ignored:word ws remembered:word ws also_ignored:word {return remembered;};',
            'word = $([a-zA-Z]+);',
            'ws = $([\\t\\n\\r ]+);'].join('\n');
        var parser = PEG.buildParser(grammar, {plugins:[bonsai]});
        var parsed = parser.parse('only keep second');
        expect(parsed).toBe("keep");
    });

    describe("sequence", function () {
        var parser = PEG.buildParser(
                ['simple_sequence = first:word $([ \\n\\r\\t]+) second:word;',
                 'word = $([a-zA-Z]+);'].join('\n'),
                {plugins:[bonsai]});
        var parsed = parser.parse('hello world', {startRule: 'simple_sequence'});
        it("produces an object when keys are provided in a sequence", function () {
            expect(typeof parsed).toBe("object");
        });
        it("maps keys to values", function () {
            expect(parsed.first).toBe('hello');
            expect(parsed.second).toBe('world');
        });
    });

    describe("flattening", function () {
        it("returns a single value when there is only one key and that key is '_'", function () {
            var parser = PEG.buildParser('bracketed = "[" _:$([a-z]+) "]"', {plugins:[bonsai]});
            var parsed = parser.parse('[bracketed]');
            expect(parsed).toBe('bracketed');
        });
        it("returns an object when there is only one key and that key is not '_'", function () {
            var parser = PEG.buildParser('bracketed = "[" matched:$([a-z]+) "]"', {plugins:[bonsai]});
            var parsed = parser.parse('[bracketed]');
            expect(parsed.matched).toBe('bracketed');
        });
        it("can be used to flatten a list", function () {
            var grammar = [
                'intlist = (_:integer ("," ws? &integer)?)*;',
                'integer = [0-9]+ { return parseInt(text()); };',
                'ws = $([ \\r\\n\\t]+);'
            ].join('\n');
            var parser = PEG.buildParser(grammar, {plugins:[bonsai]});
            var parsed = parser.parse('0, 1,2, 3,4');
            expect(parsed).toEqual([0,1,2,3,4]);
        });
    });

    describe("behavior for undefined values", function () {
        it("by default elides key-value pairs where the value is `null` or `undefined`", function () {
            var parser = PEG.buildParser("rule = first:'one' ' '? second:'two'?", {plugins:[bonsai]});
            expect(parser.parse('one two')).toEqual({first: 'one', second: 'two'});
            expect(parser.parse('one')).not.toEqual({first: 'one', second: null});
            expect(parser.parse('one').second).toBeUndefined();
            expect(parser.parse('one')).toEqual({first: 'one'});
        });
        it("can optionally keep attributes with `null` or `undefined` values", function () {
            var parser = PEG.buildParser("rule = first:'one' ' '? second:'two'?", {plugins:[bonsai], bonsaiPlugin:{ keepUndefined:true }});
            expect(parser.parse('one two')).toEqual({first: 'one', second: 'two'});
            expect(parser.parse('one')).toEqual({first: 'one', second: null});
            expect(parser.parse('one').second).toBeDefined();
        });
    });

});
