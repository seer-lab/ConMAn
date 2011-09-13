%***********************************************************
% RVK (Remove Volatile Keyword) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator removes the 
% the volatile keyword.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine variable_declaration
	[attr labelM] [repeat modifier] [rest_of_variable_declaration] [NL]
    	| [attr labelM] [repeat modifier] [rest_of_variable_declaration] /* 'MUTANT: [stringlit] */ [NL]
end redefine

define rest_of_variable_declaration
	[type_specifier] [variable_declarators] '; 
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
		"RVK"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
		% Remove all instances of volatile modifiers in
		%variable declarations one at a time
        		P [MutateVolatileDel]
end function

%------------------------------------------------------------
% Match all variable declarations that have a volatile 
% modifier and then perform the following 3 steps for each:
%	1. Create mutant of program with volatile modifier 
%      removed
%	2. Write mutant to a file
%	3. Reinsert volatile modifier that was removed
%------------------------------------------------------------
rule MutateVolatileDel
	replace [program]
		P 	[program]

	% only proceed for variable declarations that satisfy the requirements
	% (i.e. variable declarations that have a volatile modifier)
	where
		P 	[?doVolatileDelMutation]

	by 
		P	
			% Create the mutant version of the program
			[doVolatileDelMutation] 
			%[print] 	
			 [writeToFile]
			% Undo mutation and return to original program
			[undoVolatileDelMutation]
end rule

%------------------------------------------------------------
% Create an RVK mutant by removing Volatile from the 
% method modifier list
%------------------------------------------------------------
function doVolatileDelMutation
	replace * [variable_declaration]
		VariableModifiers[repeat modifier] RestOfDecl [rest_of_variable_declaration]

	% check that Volatile modifier is present
	where
		VariableModifiers [hasVolatileKeyword]

	% create empty list of modifiers
	construct NewVariableModifiers [repeat modifier]

	% export the old declaration modifiers and reinsert
	% once the mutant has been created and saved
	export VariableModifiers

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RVK (Removed Volatile Keyword)"

	by
		% generate hidden attribute
		'MUTATED 
		% populate new modifier list with all modifiers 
		% except Volatile
		NewVariableModifiers [generateModifiers each VariableModifiers] 
		% reinsert rest of variable declaration
		RestOfDecl
		% generate comment
		/* 'MUTANT: MutantString */ 
end function

%------------------------------------------------------------
% Reinsert the orginal variable declaration but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoVolatileDelMutation
	replace * [variable_declaration]
		'MUTATED CurrVariableModifiers[repeat modifier] 
		RestOfDecl [rest_of_variable_declaration] 
		/* 'MUTANT: MutantString [stringlit] */

	% Import the old variable modifiers
	import VariableModifiers [repeat modifier]

	by 
		% replace mutated declaration with original modifiers but 
		% leave hidden attribute
		'MUTATED VariableModifiers RestOfDecl
end function

%------------------------------------------------------------
% Check if method modifier list includes Volatile
%------------------------------------------------------------
rule hasVolatileKeyword
	match * [modifier]
		'volatile
end rule

%------------------------------------------------------------
% Generate list of modifiers for a variable declaration
% from existing list but exclude the volatile modifier.
%------------------------------------------------------------
function generateModifiers CurrModifier [modifier]
	% check that current modifier is not volatile
	where not
		CurrModifier [hasVolatileKeyword]

	% otherwise insert modifier into list
	replace [repeat modifier]
		Modifiers [repeat modifier]
	by
		Modifiers [. CurrModifier]
end function

%Include rules for writing mutants to files
include "WriteMutants.Txl"