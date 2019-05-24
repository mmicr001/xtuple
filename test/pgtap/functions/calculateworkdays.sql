BEGIN; -- Start the transaction

\ir ../util/_functions_calculateworkdays.sql

-- create test data
select createCalendar('open');
select createCalendar('both');

select createException(getWhsId(), true, current_date-5 , 0);
select createException(getWhsId(), false, current_date, 0);
select createException(getWhsId(), true, current_date+5, 0);
select createException(getWhsId(), true, current_date+10, 2);
select createException(getWhsId(), false, current_date+15, 2);

select createException(getWhsId()+1, false, current_date-2 , 3);
select createException(getWhsId()+1, true, current_date+3 , 3);

-- plan the tests
SELECT plan(27);
-- Run the tests.

-- W = WORK DAY
-- N = NON WORK DAY (WEEKEND)
-- C = EXCEPTION DAY (WHS IS CLOSED),
-- C(W) = CLOSED EXCEPTION FALLS ON A WORK DAY
-- C(N) = CLOSED EXCEPTION FALLS ON A NON WORK DAY
-- O = EXCEPTION DAY (WHS IS OPEN)
-- O(W) = OPEN EXCEPTION FALLS ON A WORK DAY
-- O(N) = OPEN EXCEPTION FALLS ON A NON WORK DAY


-- single day exceptions
select is(calculateworkdays(getWhsId(), current_date-2, current_date+2), 3::numeric, 'calculate workdays: W W C W (W) ');
select is(calculateworkdays(getWhsId(), current_date+3, current_date+7), 4::numeric, 'calculate workdays: W W O W (W) ');
select is(calculateworkdays(getWhsId(), current_date, current_date+4), 3::numeric, 'calculate workdays: C W W W (W)');
select is(calculateworkdays(getWhsId(), current_date-5, current_date-1), 4::numeric, 'calculate workdays: O W W W (W)');
select is(calculateworkdays(getWhsId(), current_date-3, current_date+1), 3::numeric, 'calculate workdays: W W W C (W)');
select is(calculateworkdays(getWhsId(), current_date+1, current_date+6), 5::numeric, 'calculate workdays: W W W O (W)');
select is(calculateworkdays(getWhsId(), current_date, current_date+6), 5::numeric, 'calculate workdays: C W W W W W (W)');
select is(calculateworkdays(getWhsId(), current_date-5, current_date+1), 5::numeric, 'calculate workdays: O W W W W W (W)');

--3 day exceptions (whs is closed)
select is(calculateworkdays(getWhsId(), current_date+13, current_date+19), 3::numeric, 'calculate workdays: W W C C C W (W)');
select is(calculateworkdays(getWhsId(), current_date+15, current_date+20), 2::numeric, 'calculate workdays: C C C W W W (W)');
select is(calculateworkdays(getWhsId(), current_date+16, current_date+20), 2::numeric, 'calculate workdays: C C W W W (W)');
select is(calculateworkdays(getWhsId(), current_date+17, current_date+20), 2::numeric, 'calculate workdays: C W W W (W)');
select is(calculateworkdays(getWhsId(), current_date+13, current_date+16), 2::numeric, 'calculate workdays: W W C (C)');
select is(calculateworkdays(getWhsId(), current_date+13, current_date+17), 2::numeric, 'calculate workdays: W W C C (C)');
select is(calculateworkdays(getWhsId(), current_date+13, current_date+18), 2::numeric, 'calculate workdays: W W C C C (C)');

--3 day exceptions (whs is open)
select is(calculateworkdays(getWhsId(), current_date+8, current_date+14), 6::numeric, 'calculate workdays: W W O O O W (W)');
select is(calculateworkdays(getWhsId(), current_date+10, current_date+15), 5::numeric, 'calculate workdays: O O O W W (C)');
select is(calculateworkdays(getWhsId(), current_date+11, current_date+15), 4::numeric, 'calculate workdays: O O W W (C)');
select is(calculateworkdays(getWhsId(), current_date+12, current_date+15), 3::numeric, 'calculate workdays: O W W (C)');
select is(calculateworkdays(getWhsId(), current_date+6, current_date+11), 5::numeric, 'calculate workdays: W W W W O (O)');
select is(calculateworkdays(getWhsId(), current_date+6, current_date+12), 6::numeric, 'calculate workdays: W W W W O O (O)');
select is(calculateworkdays(getWhsId(), current_date+6, current_date+13), 7::numeric, 'calculate workdays: W W W W O O O (W)');

-- non workdays and exceptions
select is(calculateworkdays(getWhsId()+1, current_date-8, current_date-5), 2::numeric, 'calculate workdays: N W W (W)');
select is(calculateworkdays(getWhsId()+1, current_date-12, current_date-7), 3::numeric, 'calculate workdays: W W W N N (W)');
select is(calculateworkdays(getWhsId()+1, current_date-9, current_date-7), 0::numeric, 'calculate workdays: N N (W) ');
select is(calculateworkdays(getWhsId()+1, current_date-4, current_date+4), 4::numeric, 'calculate workdays: W W C(N) C(N) C(W) C(W) W W (W) ');
select is(calculateworkdays(getWhsId()+1, current_date+2, current_date+8), 6::numeric, 'calculate workdays: W W O(N) O(N) O(W) O(W) W W (W)');

-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK; -- We don’t commit the transaction, this means tests don’t change the database in anyway