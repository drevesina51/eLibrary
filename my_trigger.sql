CREATE OR REPLACE FUNCTION tt.t1() RETURNS trigger
	LANGUAGE plpgsql
	AS $$DECLARE
		id integer;
BEGIN
	RAISE NOTICE 'trigger 1';
	id :=  NEW.section_id;
	WHILE (id IS NOT NULL)
	LOOP
		IF EXISTS (SELECT * FROM tt.subscribe
				   WHERE ((contract_id = NEW.contract_id)
						AND (section_id = id)))
		THEN
			RAISE NOTICE 'Subscription error: One or more sections are already present in other subscriptions';
			RETURN NULL;
		END IF;
		id := (SELECT main_section_id FROM tt.section
			   WHERE  (section_id = id));
	END LOOP;
	RETURN NEW;
END;$$;

COMMENT ON FUNCTION tt.t1() IS 'Триггер 1:
При оформлении подписки на раздел необходимо убедиться, что нет активных подписок на этот раздел. Если есть, то оформление отменяется.';

CREATE OR REPLACE TRIGGER t1
	BEFORE INSERT ON tt.subscribe
	FOR EACH ROW
	EXECUTE FUNCTION tt.t1();




CREATE OR REPLACE FUNCTION tt.t3() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
		id integer;
BEGIN
	RAISE NOTICE 'trigger 3';	
	INSERT INTO tt.section_edition (section_id, edition_id)
		SELECT NEW.section_id, edition_id FROM tt.edition
			WHERE LOWER(title) LIKE LOWER(CONCAT('%',NEW.title,'%'));
	RETURN NEW;
END;$$;

COMMENT ON FUNCTION tt.t3() IS 'Триггер 3:
При добавлении нового раздела, включать в него все издания, в названии которых есть название раздела.';

CREATE OR REPLACE TRIGGER t3 
	AFTER INSERT ON tt.section
	FOR EACH ROW
	EXECUTE FUNCTION tt.t3();