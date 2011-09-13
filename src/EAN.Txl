%***********************************************************
% EAN (Exchange Atomic Call with Non-Atomic) Mutator
% Jeremy S. Bradbury

% Copyright 2006, 2007 J.S. Bradbury

% Description: This mutation operator replaces all calls to 
% the getandSet method with a get followed by a set call
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine declaration_or_statement
	[getandset_statementordeclaration]
    |    [local_variable_declaration] 
    |   [class_declaration]
    |   [statement]
end redefine

define getandset_statementordeclaration
	[opt type_specifier] [getandset_statement]
end define

define getandset_statement
	[attr labelM] [unary_expression] '= [id] '. 'getandSet '( [expression] ') ';
	| [attr labelM]  [unary_expression] '= [id] '. 'get '( ') '; [NL]
	 [id] '. 'set '( [expression] ') ';  /* 'MUTANT: [stringlit] */
end define

define labelM
	'MUTATED
end define

%------------------------------------------------------------
% Main rule, followed by other rules in topological order
%------------------------------------------------------------
function main
	% initialize and export a mutant count that will be used in 
	% file name / folder name generation
	construct MutantCount [number]
		0
    	export MutantCount

	% initialize and export the name of the current mutant which 
	% will be used for folder name generation
	construct MutantOpName [stringlit]
		"EAN"
	export MutantOpName

	replace [program] 
        		P [program]

	by
		% Replace all GetAndSet calls with get followed by a set call
		P [MutateGetAndSet]
end function

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with getandSet() changed
% 	   to get() and set()
%	2. Write mutant to a file
%	3. Reinsert GetAndSet that was removed
%------------------------------------------------------------
rule MutateGetAndSet
	replace [program]
		P 	[program]

	% only proceed for getandSet() statements
	where
		P 	[?doReplaceGetAndSet]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceGetAndSet] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceGetAndSet]
end rule

%------------------------------------------------------------
% Create an EAN mutant by replacing getandSet()
% statements with a get() and set()
%------------------------------------------------------------
function doReplaceGetAndSet
	replace * [getandset_statement]
		UExpr [unary_expression] '= TempId [id] '. 'getandSet '( GSExpr [expression] ') ';

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"EAN (Exchange Atomic Call with Non-Atomic)"

	by
		% Replace with the getandSet() statement
		'MUTATED UExpr '= TempId '. 'get '( ') '; 
	 	TempId '. 'set '( GSExpr ') ';  /* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the original getandSet statement but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceGetAndSet
	replace * [getandset_statement]
		'MUTATED UExpr [unary_expression] '= TempId [id] '. 'get '( ') '; 
	 	TempId2 [id] '. 'set '( GSExpr [expression] ') ';  /* 'MUTANT: MutantString [stringlit] */
% we don't check that TempId = TempId2 because the only way this statement exists is if we create it
	by 
		'MUTATED UExpr '= TempId '. 'getandSet '( GSExpr ') ';
end function

%Include rules for writing mutants to files
include "WriteMutants.Txl"