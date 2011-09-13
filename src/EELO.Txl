%***********************************************************
% EELO (Exchange Explicit Lock Objects) Mutator
% Jeremy S. Bradbury

% Copyright 2006-2007 J.S. Bradbury

% Revision history:

% Description: 
% This operator will exchange explicit lock objects

% Limitations:
% Currently this operator only exchanges objects for
% calls to the lock() method. In the future we plan to extend 
% this operator to calls to the tryLock() and lockInterruptibly()
%methods
%***********************************************************

% Base grammar, and grammar override files
include "Java.Grm"
include "JavaCommentOverrides.Grm"

% Local grammar overrides
define labelM
	'MUTATED
end define

redefine statement
    [locking_statement]
    |    [label_statement]        
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
    |   [synchronized_statement]
    |   [try_statement]
    |   [block]
end redefine

define locking_statement
    	[attr labelM] [locking_statement2]
    	| [attr labelM] /* 'MUTANT: [stringlit] */ [NL] [locking_statement2]
end define

define locking_statement2
    	 [lock_statement]
	| [trylock_statement]
	|  [lockinterruptibly_statement]
end define

define lock_statement
	[id]'.'lock [repeat component] '; [NL]
         'try [block] [repeat catch_clause] [finally_clause]    [NL]
end define

define trylock_statement
	'if '( [id]'.'tryLock [repeat component] ') '{ [IN][NL]
	          'try [block] [repeat catch_clause] [finally_clause]    [NL] [EX]
	'}  [NL]
end define

define lockinterruptibly_statement
	'try '{ [IN] [NL]
		[id]'.'lockInterruptibly [repeat component] '; [NL]
	         'try [block] [repeat catch_clause] [finally_clause]    [NL] [EX]
	 '}    'catch '( 'InterruptedException [variable_name] ') [block] 
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
		"EELO"
	export MutantOpName

	replace [program] 
 		P [program]

    	by	% Exchange lock objects for all nested lock method calls
        		P 	[MutateExchangeLocks]
		% Replace MUTATED attributes for next pass
		[Clean]
end function

%------------------------------------------------------------
% Perform the following 3 steps for each:
%	1. Exchange two lock objects.
%	2. Write mutant to a file
% 	3. Switch lock objects back to original locations
%------------------------------------------------------------
rule MutateExchangeLocks
	replace [program]
		P 	[program]

	where
		P 	[?doExchangeExplicitLocks]
	
	by 
		P	% Create the mutant version of the program
			[doExchangeExplicitLocks] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoExchangeExplicitLocks]
end rule

%------------------------------------------------------------
% Create a mutant by exchanging the lock objects
%------------------------------------------------------------
function doExchangeExplicitLocks
	replace * [locking_statement]
		LockingStatement [locking_statement] 

	deconstruct LockingStatement
		LockingStatement2 [locking_statement2]

	export LockingStatement2
		
	deconstruct LockingStatement2
		LockStmt [lock_statement]
		
	deconstruct LockStmt
		ID [id] '. 'lock Comps [repeat component] '; 
         		'try TryBlock [block] CatchClauses [repeat catch_clause] FinallyClause [finally_clause]  
		
	deconstruct TryBlock
	    '{                  
         		TryStuff [repeat declaration_or_statement]
	    '}
	
	deconstruct * [statement] TryStuff
		LockingStatementB [locking_statement]	

	deconstruct LockingStatementB
		LockingStatementB2 [locking_statement2]
		
	deconstruct LockingStatementB2
		LockStmtB [lock_statement]
		
	deconstruct LockStmtB
		ID_B [id] '. 'lock Comps_B [repeat component] '; 
         		'try TryBlock_B [block] CatchClauses_B [repeat catch_clause] 
		FinallyClause_B [finally_clause]  

	construct LockStmt_new [lock_statement]
		ID_B '. 'lock Comps '; 
         		'try TryBlock [replaceInnerLock ID] CatchClauses FinallyClause 

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"EELO (Exchange Explicit Lock Objects)"

	by
		'MUTATED /* 'MUTANT: MutantString */ LockStmt_new
end function


%------------------------------------------------------------
% The EELO operator switches the outer and inner lock
% object in the case of two nested locked regions. This
% function replaces the inner lock object with the outer lock
% object
.%------------------------------------------------------------
function replaceInnerLock ID [id]
	replace * [lock_statement]
		LStmt [lock_statement]
	
	deconstruct LStmt
		ID_B [id] '. 'lock Comps_B [repeat component] '; 
         		'try TryBlock_B [block] CatchClauses_B [repeat catch_clause] 
		FinallyClause_B [finally_clause]  
	
	by
		ID  '. 'lock Comps_B'; 
         		'try TryBlock_B CatchClauses_B FinallyClause_B		
end function

%------------------------------------------------------------
% Switch the lock objects back but leave the
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoExchangeExplicitLocks
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
	
	import LockingStatement2 [locking_statement2]

	by 
		'MUTATED LockingStatement2
end function

%------------------------------------------------------------
% Check if lock method call is to lock() method
%------------------------------------------------------------
rule hasLock
	match * [dot_id]
		'. 'lock
end rule

%------------------------------------------------------------
%Remove MUTATED attribute for pass with different method call
%------------------------------------------------------------
rule Clean
	replace [locking_statement]
		LStmt [locking_statement]
	deconstruct LStmt
		'MUTATED LStmt2 [locking_statement2]
	by
		LStmt2
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"
