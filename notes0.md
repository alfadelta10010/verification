# Initial Slides Notes

## Verification Plan
- The verification plan is derived from the hardware specification and contains a description of what features need to be exercised and the techniques to be used.
- May include the following:
	- directed or random testing,
	- assertions,
	- HW/SW co-verification,
	- emulation, or
	- use of verification IP.

## Verification Methodology Manual
- The Verification Methodology Manual for SystemVerilog is a blueprint for system-on-chip (SoC) verification success.
- 2000s: vera language (RVM methodology) and e langauage (eRM methodology)
- SystemVerilog – HDVL (Hardware Design and Verification Language)
- Methodologies for SV:
	- OVM (Open Verification Methodology) - Cadence
	- AVM (Advanced Verification Methodology) - Mentor Graphics
	- VMM (Verification Methodology Manual) - Synopsis
	- UVM (Universal Verification Methodology) – Accellera Company

## Testbench functionality
- Determine the correctness of the DUT
- This is accomplished by the following steps.
	- Generate stimulus
	- Apply stimulus to the DUT
	- Capture the response
	- Check for correctness
	- Measure progress against the overall verification goals

## Directed Testing Approach:
- Look at the hardware specicication and write a verification plan with a list of tests, each of which concentrated on a set of related features
- (+) Produces almost immediate results
- (+) Given ample time and staffing, directed testing is sufficient to verify nany designs
- (-) When the design complexity doubles, it takes twice as a long to complite or requires twice as many people to implement
- `<Insert graph: Directed test progress over time>`

### Directed Testing Procedure:
- You write stimulus vectors that exercise the features in the DUT.
- You then simulate the DUT with these vectors and manually review the resulting log ﬁles and waveforms to make sure the design does what you expect.
- Once the test works correctly, you check it off in the veriﬁcation plan and move to the next one.
- This incremental approach makes steady progress

## Constrained Random Testing Approach
- RTG: Random TestVector generation
- `<Insert graph: Directed Test vs Random test progress over time>`
- We call it constrained random testing, as we give a constrianed set of values
- Takes longer to build a constrained-random test bench than direct testing, so there may be a a signiﬁcant delay before the ﬁrst test can be run.
- Every random test created shares the common testbench, as opposed to directed tests where each test is written from scratch.
- As a result, the single constrained-random testbench is verifying faster than the many directed testbenches
- Constrained-random: While we want the simulator to generate the stimulus, we do not want them to be entirely random, we constrain them to relevant stimuli
### Coverage
- Random tests often cover a wider space than a directed test
- This wider coverage leads to illegal areas and overalling tests
- Illegal areas are avoided with stronger constraints on the random test generation
- Overlapping tests are used to find bugs that were missed earlier
- Writing directed tests for features not covered by the random test are required

> If you create a random testbench, you can always constrain it to created directed tests, but a directed testbench can never be turned into a true random testbench.

### Paths to achieve complete coverage
- Write a constrained-random test with test vectors
- Run with many different seeds, look at the coverage
- Check for functionalility that was not covered, and write constraints that weren't covered
- Repeat until coverage improves and reaches 100%
- If coverage stagnates, write directed tests for the test

## Principles of Verification
- Constrained-random stimulus:
	- Random stimulus is crucial for exercising complex designs instead of applying directed test stimulus
- Functional coverage
	- When using random stimuli, we need functional coverage metric to measure verification progress
- Layered testbench using transactors
	- We need automated way to predict the results: A reference model or scoreboard
	- Building the testbench infrastructure includuing self-prediction
	- A layered testbench helps you control the complexity by breaking the problem down 
- Common testbench for all tests
	- We can build a testbench infrastructure that can be shared by all tests and does not have to be continually modified	
- Test case-specific code kept separate from the test bench
	- Code specific to a a single test must be kept separate  
