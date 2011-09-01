%***********************************************************
% ELPA (Exchange Lock/Permit Acquisition) Mutator
% Jeremy S. Bradbury

% Copyright 2006-2007 J.S. Bradbury

% Description: 
% This operator will replaces permit acquisition methods in semaphores
% and lock methods in Explicit Locks. Specifically, it will do the following exchanges:
%
% lock -> tryLock
% lock -> lockInterruptibly
% tryLock -> lock
% tryLock -> lockInterruptibly
% lockInterruptibly -> lock
% lockInterruptibly -> tryLock
% 
% acquire -> tryAcquire
% acquire -> acquireUninterruptibly 
% tryAcquire -> acquire
% tryAcquire -> acquireUninterruptibly 
% acquireUninterruptibly -> tryAcquire
% acquireUninterruptibly -> acquire

% Future work:
% Currently the implementation replaces any occurrence of the above methods and
% does not check the type of object associated with the method. In the future we 
% plan to check the type of object (e.g., check that the acquire method is associated
% with a semaphore.)
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
    |    [acquiring_statement]
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

% locking redefines...

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

%acquire redefines...

define acquiring_statement
    	[attr labelM] [acquiring_statement2]
    	| [attr labelM] /* 'MUTANT: [stringlit] */ [NL] [acquiring_statement2]
    	| [attr labelM] /* 'MUTANT: [stringlit] */ [NL] [acquiring_statement2]
	[repeat declaration_or_statement]
end define

define acquiring_statement2
    	 [acquire_statement]
	| [tryacquire_statement]
	| [acquireuninterruptibly_statement]
end define

define acquireuninterruptibly_statement
	[id] '. 'acquireUninterruptibly [repeat component] '; [NL]
end define

define tryacquire_statement
	'if '( [id] '. 'tryAcquire [repeat component] ') 
	[statement]
	|  [id] '. 'tryAcquire [repeat component] '; [NL]
end define

define acquire_statement
	'try '{ [IN] [NL]
		[id] '. 'acquire [repeat component] '; [NL]
		[repeat declaration_or_statement]  [NL] [EX]
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
		"ELPA"
	export MutantOpName

	replace [program] 
 	       P [program]

    	by
			% Replace all lock method calls
        		P 	[MutateLockLockInterruptibly]
			% Replace MUTATED attributes for next pass
			[CleanLock]

	        		[MutateLockTryLock]
			% Replace MUTATED attributes for next pass
			[CleanLock]

	        		[MutateTryLockLock]
			% Replace MUTATED attributes for next pass
			[CleanLock]
		
			[MutateTryLockLockInterruptibly]
			% Replace MUTATED attributes for next pass
			[CleanLock]

			[MutateLockInterruptiblyLock]
			% Replace MUTATED attributes for next pass
			[CleanLock]
		
			[MutateLockInterruptiblyTryLock]
			% Replace MUTATED attributes for next pass
			[CleanLock]

			% Replace all acquire semaphore method calls

			[MutateTryAcquireAcquireUninterruptibly]
			% Replace MUTATED attributes for next pass
			[CleanAcquire]

			[MutateTryAcquireAcquire]
			% Replace MUTATED attributes for next pass
			[CleanAcquire]		

			[MutateAcquireUninterruptiblyTryAcquire]
			% Replace MUTATED attributes for next pass
			[CleanAcquire]		

			[MutateAcquireUninterruptiblyAcquire]
			% Replace MUTATED attributes for next pass
			[CleanAcquire]

			[MutateAcquireAcquireUninterruptibly]
			% Replace MUTATED attributes for next pass
			[CleanAcquire]

			[MutateAcquireTryAcquire]
			% Replace MUTATED attributes for next pass
			[CleanAcquire]	
end function


%**************************************************************
%**************************************************************
% LOCK -> LOCKINTERRUPTIBLY
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all lock method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with lock replaced
%	by lockInterruptibly
%	2. Write mutant to a file
%	3. Reinsert lock method call that was replaced
%------------------------------------------------------------
rule MutateLockLockInterruptibly
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceLockLockInterruptibly]
	
	by 
		P	% Create the mutant version of the program
			[doReplaceLockLockInterruptibly] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceLockLockInterruptibly]
end rule

%------------------------------------------------------------
% Create a mutant by replacing lock with 
% lockInterruptibly
%------------------------------------------------------------
function doReplaceLockLockInterruptibly
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

	construct CatchVar [variable_name] 
		'e
	
	construct CatchBlock [block]
		'{
			;
		'}
	
	construct LockInterruptiblyStmt [lockinterruptibly_statement]
		'try '{
			ID '. 'lockInterruptibly Comps '; 
		         'try TryBlock CatchClauses FinallyClause 
		 '} 'catch '( 'InterruptedException CatchVar ') CatchBlock  

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ LockInterruptiblyStmt
end function

%------------------------------------------------------------
% Reinsert the orginal lock method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceLockLockInterruptibly
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
		
	deconstruct LockingStatement
		LockInterruptiblyStmt [lockinterruptibly_statement]

	import LockingStatement2 [locking_statement2]

	by
		% switch back time but leave hidden attribute
		'MUTATED LockingStatement2
end function


%**************************************************************
%**************************************************************
% LOCK -> TRYLOCK
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all lock method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with lock replaced
%	by tryLock
%	2. Write mutant to a file
%	3. Reinsert lock method call that was replaced
%------------------------------------------------------------
rule MutateLockTryLock
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceLockTryLock]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceLockTryLock] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceLockTryLock]
end rule

%------------------------------------------------------------
% Create a mutant by replacing a lock call with
% tryLock
%------------------------------------------------------------
function doReplaceLockTryLock
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
	
	construct TryLockStmt [trylock_statement]
		'if '( ID'.'tryLock Comps ') '{ 
		          'try TryBlock CatchClauses FinallyClause
		'}  

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ TryLockStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceLockTryLock
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
	
	deconstruct LockingStatement
		TryLockStmt [trylock_statement]

	import LockingStatement2 [locking_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED LockingStatement2
end function


%**************************************************************
%**************************************************************
% TRYLOCK -> LOCKINTERRUPTIBLY
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all tryLock method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with tryLock replaced
%	by lockInterruptibly
%	2. Write mutant to a file
%	3. Reinsert tryLock method call that was replaced
%------------------------------------------------------------
rule MutateTryLockLockInterruptibly
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceTryLockLockInterruptibly]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceTryLockLockInterruptibly] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceTryLockLockInterruptibly]
end rule

%------------------------------------------------------------
% Create a mutant by replacing tryLock with
% lockInterruptibly
%------------------------------------------------------------
function doReplaceTryLockLockInterruptibly
	replace * [locking_statement]
		LockingStatement [locking_statement] 

	deconstruct LockingStatement
		LockingStatement2 [locking_statement2]

	export LockingStatement2
		
	deconstruct LockingStatement2
		TryLockStmt [trylock_statement]
			
	deconstruct TryLockStmt 
	'if '( ID [id] '.'tryLock Comps [repeat component] ') '{ 
	          'try TryBlock [block] CatchClauses [repeat catch_clause] FinallyClause [finally_clause]
	'}  

	construct CatchVar [variable_name] 
		'e
	
	construct CatchBlock [block]
		'{
			;
		'}
	
	construct LockInterruptiblyStmt [lockinterruptibly_statement]
		'try '{
			ID '. 'lockInterruptibly Comps '; 
		         'try TryBlock CatchClauses FinallyClause 
		 '} 'catch '( 'InterruptedException CatchVar ') CatchBlock  


	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ LockInterruptiblyStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceTryLockLockInterruptibly
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
	
	deconstruct LockingStatement
		LockInterruptiblyStmt [lockinterruptibly_statement]

	import LockingStatement2 [locking_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED LockingStatement2
end function


%**************************************************************
%**************************************************************
% TRYLOCK -> LOCK
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all tryLock method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with tryLock replaced
%	by lock
%	2. Write mutant to a file
%	3. Reinsert tryLock method call that was replaced
%------------------------------------------------------------
rule MutateTryLockLock
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceTryLockLock]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceTryLockLock] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceTryLockLock]
end rule

%------------------------------------------------------------
% Create a mutant by replacing tryLock with lock
%------------------------------------------------------------
function doReplaceTryLockLock
	replace * [locking_statement]
		LockingStatement [locking_statement] 

	deconstruct LockingStatement
		LockingStatement2 [locking_statement2]

	export LockingStatement2
		
	deconstruct LockingStatement2
		TryLockStmt [trylock_statement]
			
	deconstruct TryLockStmt 
		'if '( ID [id] '.'tryLock Comps [repeat component] ') '{ 
		          'try TryBlock [block] CatchClauses [repeat catch_clause] FinallyClause [finally_clause]
		'}  

	construct LockStmt [lock_statement]
		ID '. 'lock Comps '; 
         		'try TryBlock CatchClauses FinallyClause  
	
	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ LockStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceTryLockLock
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
	
	deconstruct LockingStatement
		LockStmt [lock_statement]

	import LockingStatement2 [locking_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED LockingStatement2
end function


%**************************************************************
%**************************************************************
% LOCKINTERRUPTIBLY -> LOCK
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all lockInterruptibly method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with lockInterruptibly replaced
%	by lock
%	2. Write mutant to a file
%	3. Reinsert lockInterruptibly method call that was replaced
%------------------------------------------------------------
rule MutateLockInterruptiblyLock
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceLockInterruptiblyLock]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceLockInterruptiblyLock] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceLockInterruptiblyLock]
end rule

%------------------------------------------------------------
% Create a mutant by replacing lockInterruptibly
% by lock
%------------------------------------------------------------
function doReplaceLockInterruptiblyLock
	replace * [locking_statement]
		LockingStatement [locking_statement] 

	deconstruct LockingStatement
		LockingStatement2 [locking_statement2]

	export LockingStatement2
		
	deconstruct LockingStatement2
		LockInterruptiblyStmt [lockinterruptibly_statement]		
	
	deconstruct LockInterruptiblyStmt
		'try '{
			ID [id] '. 'lockInterruptibly Comps [repeat component] '; 
		          'try TryBlock [block] CatchClauses [repeat catch_clause] FinallyClause [finally_clause]
		  '} 'catch '( 'InterruptedException CatchVar [variable_name] ') CatchBlock [block]	
			
	construct LockStmt [lock_statement]
		ID '. 'lock Comps '; 
         		'try TryBlock CatchClauses FinallyClause  
	
	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ LockStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceLockInterruptiblyLock
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
	
	deconstruct LockingStatement
		LockStmt [lock_statement]

	import LockingStatement2 [locking_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED LockingStatement2
end function


%**************************************************************
%**************************************************************
% LOCKINTERRUPTIBLY -> TRYLOCK
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all lockInterruptibly method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with lockInterruptibly replaced
%	by tryLock
%	2. Write mutant to a file
%	3. Reinsert lockInterruptibly method call that was replaced
%------------------------------------------------------------
rule MutateLockInterruptiblyTryLock
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceLockInterruptiblyTryLock]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceLockInterruptiblyTryLock] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceLockInterruptiblyTryLock]
end rule

%------------------------------------------------------------
% Create a mutant by replacing lockInterruptibly
% with tryLock
%------------------------------------------------------------
function doReplaceLockInterruptiblyTryLock
	replace * [locking_statement]
		LockingStatement [locking_statement] 

	deconstruct LockingStatement
		LockingStatement2 [locking_statement2]

	export LockingStatement2
		
	deconstruct LockingStatement2
		LockInterruptiblyStmt [lockinterruptibly_statement]		
	
	deconstruct LockInterruptiblyStmt
		'try '{
			ID [id] '. 'lockInterruptibly Comps [repeat component] '; 
		          'try TryBlock [block] CatchClauses [repeat catch_clause] FinallyClause [finally_clause]
		  '} 'catch '( 'InterruptedException CatchVar [variable_name] ') CatchBlock [block]	
			
	construct TryLockStmt  [trylock_statement]
		'if '( ID '.'tryLock Comps ') '{ 
	        		'try TryBlock CatchClauses FinallyClause
		'}  	
	
	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ TryLockStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceLockInterruptiblyTryLock
	replace * [locking_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ LockingStatement [locking_statement2]
	
	deconstruct LockingStatement
		TryLockStatement [trylock_statement]

	import LockingStatement2 [locking_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED LockingStatement2
end function

%------------------------------------------------------------
%Remove MUTATED attributes for different pass
%------------------------------------------------------------
rule CleanLock
	replace [locking_statement]
		LStmt [locking_statement]
	deconstruct LStmt
		'MUTATED LStmt2 [locking_statement2]
	by
		LStmt2
end rule


%**************************************************************
%**************************************************************
% ACQUIREUNINTERRUPTIBLY -> ACQUIRE
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all acquireUninterruptibly method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with acquireUninterruptibly replaced
%	by acquire
%	2. Write mutant to a file
%	3. Reinsert acquireUninterruptibly method call that was replaced
%------------------------------------------------------------
rule MutateAcquireUninterruptiblyAcquire
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceAcquireUninterruptiblyAcquire]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceAcquireUninterruptiblyAcquire] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceAcquireUninterruptiblyAcquire]
end rule

%------------------------------------------------------------
% Create a mutant by replacing acquireUninterruptibly
% with acquire
%------------------------------------------------------------
function doReplaceAcquireUninterruptiblyAcquire
	replace * [acquiring_statement]
		AcquiringStatement [acquiring_statement] 

	deconstruct AcquiringStatement
		AcquiringStatement2 [acquiring_statement2]

	export AcquiringStatement2
		
	deconstruct AcquiringStatement2
		AcquireUninterruptiblyStmt [acquireuninterruptibly_statement]
		
	deconstruct AcquireUninterruptiblyStmt
		ID [id] '. 'acquireUninterruptibly Comps [repeat component] '; 
         		
	construct CatchVar [variable_name] 
		'e
	
	construct CatchBlock [block]
		'{
			;
		'}
	
	construct AcquireStmt [acquire_statement]
		'try '{
			ID '. 'acquire Comps '; 
		 '} 'catch '( 'InterruptedException CatchVar ') CatchBlock  

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ AcquireStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceAcquireUninterruptiblyAcquire
	replace * [acquiring_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ AcquiringStatement [acquiring_statement2]
		
	deconstruct AcquiringStatement
		AcquireStmt [acquire_statement]

	import AcquiringStatement2 [acquiring_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED AcquiringStatement2
end function


%**************************************************************
%**************************************************************
% ACQUIREUNINTERRUPTIBLY -> TRYACQUIRE
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all acquireUninterruptibly method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with acquireUninterruptibly replaced
%	by tryAcquire
%	2. Write mutant to a file
%	3. Reinsert acquireUninterruptibly method call that was replaced
%------------------------------------------------------------
rule MutateAcquireUninterruptiblyTryAcquire
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceAcquireUninterruptiblyTryAcquire]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceAcquireUninterruptiblyTryAcquire] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceAcquireUninterruptiblyTryAcquire]
end rule

%------------------------------------------------------------
% Create a mutant by replacing acquireUninterruptibly
% with tryAcquire
%------------------------------------------------------------
function doReplaceAcquireUninterruptiblyTryAcquire
	replace * [acquiring_statement]
		AcquiringStatement [acquiring_statement] 

	deconstruct AcquiringStatement
		AcquiringStatement2 [acquiring_statement2]

	export AcquiringStatement2
		
	deconstruct AcquiringStatement2
		AcquireUninterruptiblyStmt [acquireuninterruptibly_statement]
		
	deconstruct AcquireUninterruptiblyStmt
		ID [id] '. 'acquireUninterruptibly Comps [repeat component] '; 
         		
	construct TryAcquireStmt [tryacquire_statement]
	 	ID '. 'tryAcquire Comps '; 

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ TryAcquireStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceAcquireUninterruptiblyTryAcquire
	replace * [acquiring_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ AcquiringStatement [acquiring_statement2]
		
	deconstruct AcquiringStatement
		TryAcquireStmt [tryacquire_statement]

	import AcquiringStatement2 [acquiring_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED AcquiringStatement2
end function


%**************************************************************
%**************************************************************
% ACQUIRE -> ACQUIREUNINTERRUPTIBLY
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all acquire method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with acquire replaced
%	by acquireUninterruptibly
%	2. Write mutant to a file
%	3. Reinsert acquire method call that was replaced
%------------------------------------------------------------
rule MutateAcquireAcquireUninterruptibly
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceAcquireAcquireUninterruptibly]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceAcquireAcquireUninterruptibly] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceAcquireAcquireUninterruptibly]
end rule

%------------------------------------------------------------
% Create a mutant by replacing acquire with 
% acquireUninterruptibly
%------------------------------------------------------------
function doReplaceAcquireAcquireUninterruptibly
	replace * [acquiring_statement]
		AcquiringStatement [acquiring_statement] 

	deconstruct AcquiringStatement
		AcquiringStatement2 [acquiring_statement2]

	export AcquiringStatement2
		
	deconstruct AcquiringStatement2
		AcquireStmt [acquire_statement]
		
	deconstruct AcquireStmt
         		'try '{ 
			ID [id] '. 'acquire Comps [repeat component] '; 
			Decls_Stmts [repeat declaration_or_statement] 
	 	'}    'catch '( 'InterruptedException e [variable_name] ') CatchBlock [block] 
		
	construct AcquireUninterruptiblyStmt [acquireuninterruptibly_statement]
		ID '. 'acquireUninterruptibly Comps ';
         			
	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ AcquireUninterruptiblyStmt Decls_Stmts
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceAcquireAcquireUninterruptibly
	replace * [acquiring_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ AcquiringStatement [acquiring_statement2] 
		Decls_Stmts [repeat declaration_or_statement]
		
	deconstruct AcquiringStatement
		AcquireUninterruptiblyStmt [acquireuninterruptibly_statement]

	import AcquiringStatement2 [acquiring_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED AcquiringStatement2
end function


%**************************************************************
%**************************************************************
% ACQUIRE -> TRYACQUIRE
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all acquire method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with acquire replaced
%	by tryAcquire
%	2. Write mutant to a file
%	3. Reinsert acquire method call that was replaced
%------------------------------------------------------------
rule MutateAcquireTryAcquire
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceAcquireTryAcquire]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceAcquireTryAcquire] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceAcquireTryAcquire]
end rule

%------------------------------------------------------------
% Create a mutant by replacing acquire with
% tryAcquire
%------------------------------------------------------------
function doReplaceAcquireTryAcquire
	replace * [acquiring_statement]
		AcquiringStatement [acquiring_statement] 

	deconstruct AcquiringStatement
		AcquiringStatement2 [acquiring_statement2]

	export AcquiringStatement2
		
	deconstruct AcquiringStatement2
		AcquireStmt [acquire_statement]
		
	deconstruct AcquireStmt
         		'try '{ 
			ID [id] '. 'acquire Comps [repeat component] '; 
			Decls_Stmts [repeat declaration_or_statement] 
	 	'}    'catch '( 'InterruptedException e [variable_name] ') CatchBlock [block] 

	construct IfBlock [block]
		'{
			Decls_Stmts
		'}
		
	construct IfStmt [statement]
		IfBlock
		
	construct TryAcquireStmt [tryacquire_statement]
	 	'if '( ID '. 'tryAcquire Comps ') 
			IfStmt	

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ TryAcquireStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceAcquireTryAcquire
	replace * [acquiring_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ AcquiringStatement [acquiring_statement2]
		
	deconstruct AcquiringStatement
		TryAcquireStmt [tryacquire_statement]

	import AcquiringStatement2 [acquiring_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED AcquiringStatement2
end function

%**************************************************************
%**************************************************************
% TRYACQUIRE -> ACQUIREUNINTERRUPTIBLY
%**************************************************************
%**************************************************************

%------------------------------------------------------------
% Match all tryAcquire method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with tryAcquire replaced
%	by acquireUninterruptibly
%	2. Write mutant to a file
%	3. Reinsert tryAcquire method call that was replaced
%------------------------------------------------------------
rule MutateTryAcquireAcquireUninterruptibly
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceTryAcquireAcquireUninterruptibly]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceTryAcquireAcquireUninterruptibly] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceTryAcquireAcquireUninterruptibly]
end rule

%------------------------------------------------------------
% Create a mutant by replacing tryAcquire 
% with acquireUninterruptibly
%------------------------------------------------------------
function doReplaceTryAcquireAcquireUninterruptibly
	replace * [acquiring_statement]
		AcquiringStatement [acquiring_statement] 

	deconstruct AcquiringStatement
		AcquiringStatement2 [acquiring_statement2]

	export AcquiringStatement2
		
	deconstruct AcquiringStatement2
		TryAcquireStmt [tryacquire_statement]
		
	deconstruct TryAcquireStmt
         		'if '( ID [id] '. 'tryAcquire Comps [repeat component] ') 
			IfStmt [statement]
	
	construct AcquireUninterruptiblyStmt [acquireuninterruptibly_statement]
		ID '. 'acquireUninterruptibly Comps ';
         			
	construct Decl_Stmt [declaration_or_statement]
		IfStmt
	
	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ AcquireUninterruptiblyStmt Decl_Stmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceTryAcquireAcquireUninterruptibly
	replace * [acquiring_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ AcquiringStatement [acquiring_statement2] 
		Decls_Stmts [repeat declaration_or_statement]
		
	deconstruct AcquiringStatement
		AcquireUninterruptiblyStmt [acquireuninterruptibly_statement]

	import AcquiringStatement2 [acquiring_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED AcquiringStatement2
end function


%**************************************************************
%**************************************************************
% TRYACQUIRE -> ACQUIRE
%**************************************************************
%**************************************************************


%------------------------------------------------------------
% Match all tryAcquire method calls and then perform the 
% following 3 steps for each:
%	1. Create mutant of program with tryAcquire replaced
%	by acquire
%	2. Write mutant to a file
%	3. Reinsert tryAcquire method call that was replaced
%------------------------------------------------------------
rule MutateTryAcquireAcquire
	replace [program]
		P 	[program]

	where
		P 	[?doReplaceTryAcquireAcquire]
	
	by 
		P	
			% Create the mutant version of the program
			[doReplaceTryAcquireAcquire] 
			%[print] 	
			[writeToFile]
			% Undo mutation and return to original program
			[undoReplaceTryAcquireAcquire]
end rule

%------------------------------------------------------------
% Create a mutant by replacing tryAcquire
% with acquire
%------------------------------------------------------------
function doReplaceTryAcquireAcquire
	replace * [acquiring_statement]
		AcquiringStatement [acquiring_statement] 

	deconstruct AcquiringStatement
		AcquiringStatement2 [acquiring_statement2]

	export AcquiringStatement2
		
	deconstruct AcquiringStatement2
		TryAcquireStmt [tryacquire_statement]
		
	deconstruct TryAcquireStmt
         		'if '( ID [id] '. 'tryAcquire Comps [repeat component] ') 
			IfStmt [statement]
	
	construct Decl_Stmt [declaration_or_statement]
		IfStmt
		
	construct CatchVar [variable_name] 
		'e
	
	construct CatchBlock [block]
		'{
			;
		'}
	
	construct AcquireStmt [acquire_statement]
         		'try '{ 
			ID '. 'acquire Comps '; 
			Decl_Stmt
	 	'} 'catch '( 'InterruptedException CatchVar ') CatchBlock  

	% create mutant comment to appear in source
	construct MutantString [stringlit]
		"ELPA (Exchange Lock/Permit Acquisition)"

	by
		'MUTATED /* 'MUTANT: MutantString */ AcquireStmt
end function

%------------------------------------------------------------
% Reinsert the orginal method call but leave the 
% MUTATED attribute to indicate that the mutant has already
% been created.
%------------------------------------------------------------
function undoReplaceTryAcquireAcquire
	replace * [acquiring_statement]
		'MUTATED /* 'MUTANT: MutantString [stringlit] */ AcquiringStatement [acquiring_statement2]
		
	deconstruct AcquiringStatement
		AcquireStmt [acquire_statement]

	import AcquiringStatement2 [acquiring_statement2]

	by 
		% switch back time but leave hidden attribute
		'MUTATED AcquiringStatement2
end function

%------------------------------------------------------------
%Replace MUTATED attributes for another pass
%------------------------------------------------------------
rule CleanAcquire
	replace [acquiring_statement]
		AStmt [acquiring_statement]
	deconstruct AStmt
		'MUTATED AStmt2 [acquiring_statement2]
	by
		AStmt2
end rule

%Include rules for writing mutants to files
include "WriteMutants.Txl"