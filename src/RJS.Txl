%***********************************************************
% RJS (Replace Join with Sleep) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator replaces all calls to 
% the Join method with calls to the Sleep methods for a
% fixed amount of time (10000)
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine reference
	[attr labelM] [id] '. 'join '( ')
	| [attr labelM] [id] '. 'sleep '( 10000 ')
	| [attr labelM] [id] '. 'sleep '( 10000 ') /* 'MUTANT: [stringlit] */
    	| [id] [repeat component]
end redefine

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

	% initialize and export the name of the current mutant while 
	% will be used for folder name generation
	construct MutantOpName [stringlit]
		"RJS"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
		% Replace all Join calls with a sleep call
        		P [MutateJointoSleep]
end function

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with Join changed
% 	   to Sleep
%	2. Write mutant to a file
%	3. Reinsert Join that was removed
%------------------------------------------------------------
rule MutateJointoSleep
	replace [program]
		P 	[program]

	% only proceed for ids that are Join
	where
		P 	[?doReplaceJoin]
	
	by 
		P	% Create the mutant version of the program
			[doReplaceJoin] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceJoin]
end rule

%------------------------------------------------------------
% Create a RJS mutant by replacing a Join method call
% with a Sleep method call
%------------------------------------------------------------
function doReplaceJoin
	replace * [reference]
		TempId [id] '. 'join'( ')

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RJS (Replace join() with sleep())"

	by
		% Replace with sleep method call
		'MUTATED TempId '. 'sleep '( 10000 ') /* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the Join method call but leave the 
% MUTATED attribute to indicate that the mutant
% has already been created.
%------------------------------------------------------------
function undoReplaceJoin
	replace * [reference]
		'MUTATED TempId [id] '. 'sleep '( 10000 ') /* 'MUTANT: MutantString [stringlit] */

	by 
		% switch back from Sleep to Join but 
		% leave hidden attribute
		'MUTATED TempId '. 'join '( ')
end function

%------------------------------------------------------------
% Check if id is Join
%------------------------------------------------------------
rule isJoin
	match * [id]
		'join
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"