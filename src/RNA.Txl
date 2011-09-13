%***********************************************************
% RNA (Replace NotifyAll with Notify) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Description: This mutation operator replaces all calls to 
% NotifyAll with Notify
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
redefine reference
    [new_id] [repeat component]
end redefine

redefine dot_id
    '. [new_id]
end redefine

define new_id
	[attr labelM] [id]
	| [attr labelM] [id] /* 'MUTANT: [stringlit] */
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
		"RNA"
	export MutantOpName

	replace [program] 
        		P [program]

    by
		P	% Replace all notifyAll calls with notfiy calls one at 
			% a time
        			[MutateNotifyAlltoNotify]
end function

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with notifyAll changed
% 	   to notify
%	2. Write mutant to a file
%	3. Reinsert notifyAll that was removed
%------------------------------------------------------------
rule MutateNotifyAlltoNotify
	replace [program]
		P 	[program]

	% only proceed for ids that are notifyAll
	where
		P 	[?doReplaceNotifyAll]
	
	by 
		P	% Create the mutant version of the program
			[doReplaceNotifyAll] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceNotifyAll]
end rule

%------------------------------------------------------------
% Create a RNA mutant by replacing a notifyAll method call
% with a notify method call
%------------------------------------------------------------
function doReplaceNotifyAll
	replace * [new_id]
		Idenifier [id]

	where 
		Idenifier [isNotifyAll]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RNA (Replace NotifyAll() with Notify())"

	by
		% Replace with empty syncronized statement
		'MUTATED 'notify /* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Reinsert the notifyAll method call but leave the 
% MUTATED attribute to indicate that the mutant 
% has already been created.
%------------------------------------------------------------
function undoReplaceNotifyAll
	replace * [new_id]
		'MUTATED Idenifier [id] /* 'MUTANT: MutantString[stringlit] */

	by 	% switch back from notify to notifyAll but 
		% leave hidden attribute
		'MUTATED 'notifyAll
end function

%------------------------------------------------------------
% Check if id is notifyAll
%------------------------------------------------------------
rule isNotifyAll
	match * [id]
		'notifyAll
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"