"use strict";

var PEG = require('pegjs');
var bonsai = require('../src/index.js');

describe("Bonsai", function () {
    var grammar = [
        'bigrule = simple_word:$("simple " word)?',
        '    intlist:(_:integer ("," ws? &integer)?)*',
        '    actor:("actor " _:actor)?',
        '',
        'simple_sequence = first:word ws second:word',
        '',
        'word = $([a-zA-Z]+)',
        '',
        'integer = [0-9]+ { return parseInt(text()); }',
        '',
        'ws = $([\\t\\n\\r ]+)',
        '',
        'inside_brackets = "[" _:word "]"',
        '',
        'actor = ignored:word ws remembered:word ws also_ignored:word {return remembered;}'].join('\n');
    it("Creates a parser", function() {
        var parser = PEG.buildParser(grammar, {plugins:[bonsai]});
        expect(typeof parser).toBe("object");
        expect(parser.parse).toBeDefined();
    });

    describe("sequence", function () {
        var parser = PEG.buildParser(
                ['simple_sequence = first:word $([ \\n\\r\\t]+) second:word',
                 '',
                 'word = $([a-zA-Z]+)'].join('\n'),
                {plugins:[bonsai]});
        var parsed = parser.parse('hello world', {startRule: 'simple_sequence'});
        it("Produces an object when keys are provided in a sequence", function () {
            expect(typeof parsed).toBe("object");
        });
        it("Maps keys to values", function () {
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
                'intlist = (_:integer ("," ws? &integer)?)*',
                '',
                'integer = [0-9]+ { return parseInt(text()); }',
                '',
                'ws = $([ \\r\\n\\t]+)'
            ].join('\n');
            var parser = PEG.buildParser(grammar, {plugins:[bonsai]});
            var parsed = parser.parse('0, 1,2, 3,4');
            expect(parsed).toEqual([0,1,2,3,4]);
        });
    });
    it("uses an existing action, when available", function () {
        var grammar = [
            'actor = ignored:word ws remembered:word ws also_ignored:word {return remembered;}',
            '',
            'word = $([a-zA-Z]+)',
            '',
            'ws = $([\\t\\n\\r ]+)'].join('\n');
        var parser = PEG.buildParser(grammar, {plugins:[bonsai]});
        var parsed = parser.parse('only keep second');
        expect(parsed).toBe("keep");
    });

});
