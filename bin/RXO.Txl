%***********************************************************
% RXO (Replace One Concurrency Mechanism-X with Another) Mutator
% Jeremy S. Bradbury

% Copyright 2006-2007 J.S. Bradbury

% Revision history:

% Description: 
% This operator will replace one explicit lock object with another. 

%Limitations. Currently only works with explicit locks. In the future we will extend this
%to Semaphores, etc.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
define labelM
	'MUTATED
end define

redefine reference
    [concurrency_reference]
    | [id] [repeat component]
end redefine

define concurrency_reference
	[attr labelM] [con_id] [thread_dot_id] [repeat component]
	| [attr labelM] [con_id] [thread_dot_id] [repeat component]  /* 'MUTANT: [stringlit] */
end define

define con_id
	[id]
end define

define thread_dot_id
	 '. [thread_id]	
end define

define thread_id
		'lock
	|	'lockInterruptibly
	|	'tryLock
	|	'unlock
	|	'isLocked
	%|	'signal
	%|	'signalAll
	%|	'acquire
	%|	'release
	%|	'countDown
	%|	'submit
end define

%------------------------------------------------------------
% Main rule, followed by other rules in topological order
%------------------------------------------------------------
function main
	replace [program] 
 	       P [program]

	% initialize and export a mutant count that will be used in 
	% file name / folder name generation
    	construct MutantCount [number]
		0
    	export MutantCount

	% initialize and export the name of the current mutant while 
	% will be used for folder name generation
	construct MutantOpName [stringlit]
		"RXO"
	export MutantOpName

	%Generate list of explicit lock objects
	construct ConIDs [repeat con_id]
		_ [^ P]
    	
	by	%Replace all lock objects with every other lock object
        		P 	[MutateReplaceObjects each ConIDs]

end function

%------------------------------------------------------------
% This method ensures that the MUTATED attributes
% are removed after each pass with a given ConID
%------------------------------------------------------------
function MutateReplaceObjects NewConID [con_id]
	replace [program]
		P 	[program]
			
	by 
		P	[MutateReplaceObjects2 NewConID] 
			% Replace MUTATED attributes for next pass
			[Clean]
end function
	
%------------------------------------------------------------
% Perform the following 3 steps for each:
%	1. Create mutant of program with current object replaced
%	2. Write mutant to a file
%	3. Reinsert original object that was replaced
%------------------------------------------------------------
rule MutateReplaceObjects2 NewConID [con_id]
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceObjects NewConID]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceObjects NewConID] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceObjects]
end rule

%------------------------------------------------------------
% Create a mutant by replace object with NewConID (if different)
%------------------------------------------------------------
function doReplaceObjects NewConID [con_id]
	replace * [concurrency_reference]
		Con_Ref [concurrency_reference]
	
	deconstruct Con_Ref
		CurrConID [con_id] ThreadDotID [thread_dot_id] Comps[repeat component]
	% Check that new object is not the sam as current object
	where not
		CurrConID [isSameConID NewConID]

	%Export current object to be reinserted later
	export CurrConID

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"RXO (Replace One Concurrency Mechanism with Another)"

	by
		'MUTATED NewConID ThreadDotID Comps /* 'MUTANT: MutantString */ 
end function

%------------------------------------------------------------
% Reinsert the orginal lock object but leave the 
% MUTATED attribute to indicate that the mutant 
% has already been created.
%------------------------------------------------------------
function undoReplaceObjects
	replace * [concurrency_reference]
		'MUTATED NewConID [con_id] ThreadDotID [thread_dot_id] 
		Comps [repeat component] /* 'MUTANT: MutantString [stringlit] */
		
	%Import the original lock object
	import CurrConID [con_id]

	by 
		% switch back object but leave hidden attribute
		'MUTATED CurrConID ThreadDotID Comps
end function

%------------------------------------------------------------
% Check that current object is not the same as
% new object
%------------------------------------------------------------
rule isSameConID NewConID [con_id]
	match * [con_id]
		NewConID
end rule

%------------------------------------------------------------
%Remove MUTATED attributes for another pass
%------------------------------------------------------------
rule Clean
	replace [concurrency_reference]
		ConRef [concurrency_reference]
	deconstruct ConRef
		'MUTATED ID [con_id] ThreadId [thread_dot_id]
	by
		ID ThreadId
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"
