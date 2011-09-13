%***********************************************************
% SHCR (Shift Critical Region) Mutator
% Jeremy S. Bradbury

% Copyright 2006 J.S. Bradbury

% Revision history:
%Oct. 9, 2006 - Created.
%Jan 15, 2007 - Fixed grammar to include situation where
%     we have a synchronized statement with only one statement insides (i.e., no { })
%Feb 22, 2007 - When shifting a synchronized block an extra statement was being 
%    included into the critical region but no statement on other end of crtiical region was 
%    being moved outside of critical region.

% Description: This mutation operator ...

% Limitations: This operator currently shifts only 
% synchronized block critical regions. In the future
% we plan to extend the operator to shift critical regions
% created with explicit locks, etc.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides

redefine declaration_or_statement
	 	[synchronized_statement]
	|	[declaration_or_other_statements]
    |   [block]
	|	[comment_NL]
end redefine

define declaration_or_other_statements
        [local_variable_declaration] 
    |   [class_declaration]
    |   [other_statements]
end define

redefine statement
        [synchronized_statement]
	| 	[other_statements]
    |   [block]
	|	[comment_NL]
end redefine

define other_statements
        [label_statement]        
    |   [empty_statement]
    |   [expression_statement]
    |   [if_statement]
    |   [switch_statement]
    |   [while_statement]
    |   [do_statement]
    |   [for_statement]
    |   [break_statement]
    |   [continue_statement]
    |   [return_statement]
    |   [throw_statement]
    |   [try_statement]
end define

redefine synchronized_statement
	[attr labelM] [synchronized_statement_2]
	| [attr labelM] [shifted_up_synchronized_statement] 
	| [attr labelM] [shifted_down_synchronized_statement] 
end redefine

define synchronized_statement_2
	[opt declaration_or_other_statements]
	'synchronized '( [expression] ')
	'{                                        [NL][IN] 
    		[repeat declaration_or_statement]         [EX]
	'}
	[opt declaration_or_other_statements]   
end define

define shifted_up_synchronized_statement
	/* 'MUTANT: [stringlit] */ 				[NL]
	'synchronized '( [expression] ')
	'{                                        [NL][IN] 
    		[repeat declaration_or_statement]         [EX]
	'}
	[repeat declaration_or_statement]
	[opt declaration_or_other_statements]    
end define

define shifted_down_synchronized_statement
	/* 'MUTANT: [stringlit] */ 				[NL]
	[opt declaration_or_other_statements]    
	[declaration_or_statement]
	'synchronized '( [expression] ')
	'{                                        [NL][IN] 
    		[repeat declaration_or_statement]         [EX]
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
		"SHCR"
	export MutantOpName


	replace [program] 
        		P [program]

    	by
		P	% First shift all critical regions up
        		 	[MutateShiftUpCriticalRegion]
			[Clean]
        			% Next shift all critical regions down
			[MutateShiftDownCriticalRegion]
end function

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with synchronized block
%      shifted up
%	2. Write mutant to a file
%	3. Shift synchronized block down
%------------------------------------------------------------
rule MutateShiftUpCriticalRegion
	replace [program]
		P 	[program]

	% only proceed for methods that satisfy the requirements
	where
		P 	[?doShiftUpCriticalRegion]
	
	by 
		P	% Create the mutant version of the program
			[doShiftUpCriticalRegion] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoShiftUpCriticalRegion]
end rule

%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with synchronized block
%      shifted down
%	2. Write mutant to a file
%	3. Shift synchronized block up
%------------------------------------------------------------
rule MutateShiftDownCriticalRegion
	replace [program]
		P 	[program]

	% only proceed for methods that satisfy the requirements
	% (i.e. methods that have a synchronized modifier)
	where
		P 	[?doShiftDownCriticalRegion]
	
	by 
		P	
			% Create the mutant version of the program
			[doShiftDownCriticalRegion] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoShiftDownCriticalRegion]
end rule

%------------------------------------------------------------
% Create a SHCR mutant by shifting a critical region
% up
%------------------------------------------------------------
function doShiftUpCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	deconstruct SynchStatement
		SynchStatement2 [synchronized_statement_2]
	deconstruct SynchStatement2
		S1 [declaration_or_other_statements]
		'synchronized '( Expr [expression] ') '{
			S2 [repeat declaration_or_statement]
		'}
		S3 [opt declaration_or_other_statements]
	
	deconstruct S2
		S2_rest [declaration_or_statement]	
		S2_last [repeat declaration_or_statement]		

	export S1
	export S2
	export S3

	construct S1_b [declaration_or_statement]
		S1

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"SHCR (Shift Critical Region - Up)"
	by
		'MUTATED 
		/* 'MUTANT: MutantString */
		'synchronized '( Expr ') '{
			S1_b S2_rest
		'}		
		S2_last
		S3
end function

%------------------------------------------------------------
% Shift the critical region back down and leave the 
% MUTATED attribute to indicate that a mutant for
% the critical region has already been created.
%------------------------------------------------------------
function undoShiftUpCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	deconstruct	SynchStatement 
		'MUTATED
		ShiftedStatement [shifted_up_synchronized_statement]

	% Import the old body of synchronization block
	import S1 [declaration_or_other_statements]
	import S2 [repeat declaration_or_statement]
	import S3 [opt declaration_or_other_statements]
	
	% extract body
	deconstruct ShiftedStatement 
		/* 'MUTANT: MutantString1[stringlit] */
		'synchronized '( Expr [expression] ') '{
			NewBody [repeat declaration_or_statement]
		'}
		OtherStatementAfter [declaration_or_statement]
		StatementAfter [opt declaration_or_other_statements]

	by 
		% replace mutated synchronized block with original but 
		% leave hidden attribute
		'MUTATED 
		S1
		'synchronized '( Expr ') '{
		        S2
		'}
		S3
end function

%------------------------------------------------------------
% Create a SHCR mutant by shifting a critical region
% down
%------------------------------------------------------------
function doShiftDownCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]
	
	deconstruct SynchStatement
		SynchStatement2 [synchronized_statement_2]
	deconstruct SynchStatement2
		DS1 [opt declaration_or_other_statements]
		'synchronized '( Expr [expression] ') '{
			DS2 [repeat declaration_or_statement]
		'}
		DS3 [declaration_or_other_statements] 
	deconstruct DS2
		DS2_first [declaration_or_statement]
		DS2_rest [repeat declaration_or_statement]	

	export DS1
	export DS2
	export DS3

	construct S3_b [declaration_or_statement]
		DS3

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"SHCR (Shift Critical Region - Down)"
	
	by
		'MUTATED 
		/* 'MUTANT: MutantString */
		DS1 
		DS2_first
		'synchronized '( Expr ') '{
			 DS2_rest [. S3_b]
		'}				
end function



%------------------------------------------------------------
% Shift the critical region back down and leave the 
% MUTATED attribute to indicate that the mutant 
% has already been created.
%------------------------------------------------------------
function undoShiftDownCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	deconstruct SynchStatement 
		'MUTATED
		ShiftedStatement [shifted_down_synchronized_statement]

	% Import the old body of synchronization block
	import DS1 [opt declaration_or_other_statements]
	import DS2 [repeat declaration_or_statement]
	import DS3 [declaration_or_other_statements]
	
	% extract body
	deconstruct ShiftedStatement 
		/* 'MUTANT: MutantString1[stringlit] */
		StatementBefore [opt declaration_or_other_statements]
		OtherStatementBefore [declaration_or_statement]
		'synchronized '( Expr [expression] ') '{
			NewBody [repeat declaration_or_statement]
		'}
		
	by 
		% replace mutated synchronized block with original but 
		% leave hidden attribute
		'MUTATED 
		DS1
		'synchronized '( Expr ') '{
        			DS2
		'}
		DS3
end function

%------------------------------------------------------------
%Remove MUTATED attributes for additional pass
%------------------------------------------------------------
rule Clean
	replace [synchronized_statement]
		SynchStatement[synchronized_statement]
	deconstruct SynchStatement
		'MUTATED SynchStatement2 [synchronized_statement_2]
	by
		SynchStatement2
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"
