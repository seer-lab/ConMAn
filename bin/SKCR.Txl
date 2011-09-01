%***********************************************************
% SKCR (Shrink Critical Region) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Revision history:

% Description: This mutation operator shrinks the
% the synchronizied block around a group of statements.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides

redefine synchronized_statement
	[attr labelM] [synchronized_statement_2]
	| [attr labelM] [shrunk_synchronized_statement] 
	| ...
end redefine

define shrunk_synchronized_statement
    /* 'MUTANT: [stringlit] */ 				[NL]
	[declaration_or_statement]
	'synchronized '( [expression] ')
	'{                                        [NL][IN] 
    		[repeat declaration_or_statement]         [EX]
	'}
	[ declaration_or_statement]       
	/* 'MUTANT: [stringlit] */ 				[NL]
	
end define

define synchronized_statement_2
    'synchronized '( [expression] ')
	'{                                        [NL][IN] 
        [repeat declaration_or_statement]     [EX]
    '}
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

	% initialize and export the name of the current mutant while 
	% will be used for folder name generation
	construct MutantOpName [stringlit]
		"SKCR"
	export MutantOpName
	
	replace [program] 
        		P [program]

   	 by	% shrink all instances of synchronized blocks one at 
		% a time
        		P [MutateShrinkCriticalRegion]
end function

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with synchronized block
%      shrunk
%	2. Write mutant to a file
%	3. Expand synchronized block that was shrunk
%------------------------------------------------------------
rule MutateShrinkCriticalRegion
	replace [program]
		P 	[program]

	% only proceed for methods that satisfy the requirements
	% (i.e. methods that have a synchronized modifier)
	where
		P 	[?doShrinkCriticalRegion]

	by 
		P	% Create the mutant version of the program
			[doShrinkCriticalRegion] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoShrinkCriticalRegion]
end rule

%------------------------------------------------------------
% Create a SKCR mutant 
%------------------------------------------------------------
function doShrinkCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]
	
	deconstruct SynchStatement
		SynchStatement2 [synchronized_statement_2]
	deconstruct SynchStatement2
		'synchronized '( Expr [expression] ') '{
        			Body [repeat declaration_or_statement]
		'}
	deconstruct Body
		Statement1 [declaration_or_statement]
		Statement2 [repeat declaration_or_statement]	
	
	% export the old body of the synchronized block
	export Body

	construct MiddleStatements [repeat declaration_or_statement]

	where MiddleStatements [? generateMiddle Statement2]
	
	construct M2 [repeat declaration_or_statement]
		_ [generateMiddle Statement2]
	
	import Second [declaration_or_statement]

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"SKCR (Shrink Critical Region)"

	by
		'MUTATED 
		/* 'MUTANT: MutantString */
		Statement1
		'synchronized '( Expr ') '{
			M2
		'}		
		Second
		/* 'MUTANT: MutantString */
end function

%------------------------------------------------------------
% Recursive function to generate new shrunk critical region
%------------------------------------------------------------
function generateMiddle Statement2 [repeat declaration_or_statement]
	deconstruct Statement2
		First [declaration_or_statement] Rest [repeat declaration_or_statement]
	deconstruct Rest
		Second [declaration_or_statement] More [repeat declaration_or_statement]
	export Second
	construct Temp [repeat declaration_or_statement]

	replace  [repeat declaration_or_statement]
		X [repeat declaration_or_statement]

	by 
		First Temp [generateMiddle Rest]
end function

%------------------------------------------------------------
% Return mutated code to original form but leave the
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoShrinkCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	deconstruct SynchStatement 
		'MUTATED
		ShrunkStatement [shrunk_synchronized_statement]

	% Import the old body of synchronization block
	import Body [repeat declaration_or_statement]

	% extract body
	deconstruct ShrunkStatement 
		/* 'MUTANT: MutantString1[stringlit] */
		S1 [declaration_or_statement]
		'synchronized '( Expr [expression] ') '{
			S2 [repeat declaration_or_statement]
		'}
		S3 [declaration_or_statement]  
		/* 'MUTANT: MutantString2[stringlit] */

	by 
		% replace mutated synchronized block with original but 
		% leave hidden attribute
		'MUTATED 'synchronized '( Expr ') '{
        			Body
		'}
end function

%Include rules for writing mutants to files
include "WriteMutants.Txl"
