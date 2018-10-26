INSERT INTO recurtype (recurtype_type, recurtype_table, recurtype_donecheck, 
                       recurtype_schedcol, recurtype_limit, recurtype_copyfunc, 
                       recurtype_copyargs, recurtype_delfunc) 
               VALUES ('S', 'cohead', 'isRecurSODone(cohead_id)', 'cohead_orderdate',
                       NULL, 'copycohead', '{INTEGER,TIMESTAMP WITH TIME ZONE}', NULL) 
          ON CONFLICT (recurtype_type) DO NOTHING;