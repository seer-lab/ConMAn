%***********************************************************
% ASTK (Add Static Keyword To a Method) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator add the 
% static keyword to any method that is synchronized
% and not already static. We do not consider constructors 
% because although constructors may have a synchronized 
% block in their method body, a constructor method can 
% not be synchronized.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine method_or_constructor_declaration
	[attr labelM] [method_declaration]
	| [attr labelM] /* 'MUTANT: [stringlit] */ [method_declaration]
	| [attr labelM] [constructor_declaration]
end redefine

define labelM
	'MUTATED
end define

redefine method_declaration
    	[NL] [repeat modifier] [rest_of_method_declaration]
end redefine

define rest_of_method_declaration
	[type_specifier] [method_declarator] [opt throws] [method_body]
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
		"ASTK"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
		% Add static modifier to all non-static synchronized 
		%methods one at a time
        		P [MutateStaticInsert]
end function

%------------------------------------------------------------
% Match all methods that do not have a static modifier but
% have a synchronized modifier and then perform the following 
% 3 steps for each:
%	1. Create mutant of program with static modifier added
%	2. Write mutant to a file
%	3. Remove static modifier that was inserted
%------------------------------------------------------------
rule MutateStaticInsert
	replace [program]
		P 	[program]

	% only proceed for methods that satisfy the requirements
	% (i.e. methods that are synchronized and not static)
	where
		P 	[?doStaticInsertMutation]
	
	by 
		P	
			% Create the mutant version of the program
			[doStaticInsertMutation] 
			% [print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoStaticInsertMutation]
end rule

%------------------------------------------------------------
% Create an ASTK mutant by adding static to the method 
% modifier list of a method that is synchronized and not 
% static
%------------------------------------------------------------
function doStaticInsertMutation
	replace * [method_or_constructor_declaration]
		GenDecl [method_or_constructor_declaration]
	deconstruct GenDecl
		MethodDecl [method_declaration]
	deconstruct MethodDecl
		MethodModifiers [repeat modifier] 
		RemainingDelcaration [rest_of_method_declaration]

	% check that static modifier is not present and synchronized 
	% modifier is present
	where not
		MethodModifiers [hasStaticKeyword]
	where
		MethodModifiers [hasSynchronizedKeyword]

	% create new list of modifiers
	construct StaticModifier [modifier]
		'static
	construct NewMethodModifiers [repeat modifier]
		MethodModifiers [. StaticModifier]

	% export the old declaration and reinsert it 
	% once the mutant has been created and saved
	export GenDecl

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ASTK (Added Static Keyword)"
	by
		% generate hidden attribute and comment
		'MUTATED /* 'MUTANT: MutantString */ 
		% populate new modifier list with all exisitng modifiers 
		% plus static
		NewMethodModifiers
		% reinsert rest of method declaration
		RemainingDelcaration 
end function

%------------------------------------------------------------
% Reinsert the orginal method declaration but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoStaticInsertMutation
	replace * [method_or_constructor_declaration]
		CurrGenDecl [method_or_constructor_declaration]

	% Import the old declaration
	import GenDecl [method_or_constructor_declaration]

	% extract method declaration
	deconstruct GenDecl
		SavedMethodDecl [method_declaration]

	deconstruct CurrGenDecl
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ CurrMethodDecl [method_declaration]

	by 
		% replace mutated declaration with original but leave hidden attribute
		'MUTATED SavedMethodDecl
end function

%------------------------------------------------------------
% Check if method modifier list includes static
%------------------------------------------------------------
rule hasStaticKeyword
	match * [modifier]
		'static
end rule

%------------------------------------------------------------
% Check if method modifier list includes synchronized
%------------------------------------------------------------
rule hasSynchronizedKeyword
	match * [modifier]
		'synchronized
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"