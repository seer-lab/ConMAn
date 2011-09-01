%***********************************************************
% SPCR (Split Critical Region) Mutator
% Jeremy S. Bradbury

% Copyright 2007 J.S. Bradbury

% Revision history:

% Description: This mutation operator ...

% Limitations: This operator currently splits only 
% synchronized block critical regions. In the future
% we plan to extend the operator to split critical regions
% created with explicit locks, etc.
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides

redefine synchronized_statement
		[attr labelM] [single_synchronized_statement]
	|	[attr labelM] [split_synchronized_statement]
end redefine

define single_synchronized_statement
    'synchronized '( [expression] ')
        [statement]                  [NL]
end define

define split_synchronized_statement
    /* 'MUTANT: [stringlit] */ 				[NL]
	'synchronized '( [expression] ')
	'{                                        [NL][IN] 
    		[declaration_or_statement]         [EX]
	'}
	'synchronized '( [expression] ')
	'{                                        [NL][IN] 
    		[repeat declaration_or_statement+]         [EX]
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
		"SPCR"
	export MutantOpName

	replace [program] 
        		P [program]

    	by
		P [MutateSplitCriticalRegion]
end function


%------------------------------------------------------------
% Match all methods that have a synchronized block 
% and then perform the following 3 steps for each:
%	1. Create mutant of program with synchronized block
%      split
%	2. Write mutant to a file
%	3. Merge split critical regions back into one region
%------------------------------------------------------------
rule MutateSplitCriticalRegion
	replace [program]
		P 	[program]

	% only proceed for methods that satisfy the requirements
	where
		P 	[?doSplitCriticalRegion]

	by 
		P	% Create the mutant version of the program
			[doSplitCriticalRegion] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoSplitCriticalRegion]
end rule

%------------------------------------------------------------
% Create a SPCR mutant by splitting a critical
% region
%------------------------------------------------------------
function doSplitCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	deconstruct SynchStatement
		SynchStatement2 [single_synchronized_statement]
	deconstruct SynchStatement2
		'synchronized '( Expr [expression] ') 
				Body [statement]
	deconstruct Body
		'{
			First [declaration_or_statement]
			Second [repeat declaration_or_statement+]
		'}
	
	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"SPCR (Split Critical Region)"

 	construct SP_Synchronized [split_synchronized_statement]
	/* 'MUTANT: MutantString */ 				
	'synchronized '( Expr ')
	'{                                       
    		First        
	'}
	'synchronized '( Expr ')
	'{                                        
    		Second         
	'}

	by
		'MUTATED SP_Synchronized	
end function


%------------------------------------------------------------
% Undo the splitting of the critical region but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoSplitCriticalRegion
	replace * [synchronized_statement]
		SynchStatement [synchronized_statement]

	deconstruct SynchStatement 
		'MUTATED
		SplitStatement [split_synchronized_statement]

	% extract body
	deconstruct SplitStatement 
		/* 'MUTANT: MutantString1[stringlit] */ 				
		'synchronized '( Expr [expression] ')
		'{                                       
    			First [declaration_or_statement]        
		'}
		'synchronized '( Expr2 [expression] ')
		'{                                        
    			Second [repeat declaration_or_statement+]        
		'}

	construct FirstRepeat [repeat declaration_or_statement]
		First

	construct OldBody [repeat declaration_or_statement]
		FirstRepeat [. Second]

	by 
		% replace mutated synchronized block with original but 
		% leave hidden attribute
		'MUTATED 
		'synchronized '( Expr ') '{
			OldBody
		'}
end function

%Include rules for writing mutants to files
include "WriteMutants.Txl"