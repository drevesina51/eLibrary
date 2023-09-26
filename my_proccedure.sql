drop procedure if exists tt.p1;
create procedure tt.p1(
	p1_edition_id integer, 
	p1_contract_id integer
)
AS $$
	DECLARE
		overdue_days integer;
		requestid integer;
	BEGIN		
		--для отладки выведем, что передали, с помощью % передаем данные в сообщение
		RAISE NOTICE 'edition_id = %, contract_id = %', p1_edition_id, p1_contract_id;
		
		--определение id запроса для возврата
		SELECT tt.request.request_id FROM tt.request INTO requestid
		INNER JOIN tt.request_edition ON tt.request.request_id = tt.request_edition.request_id
    	WHERE ((tt.request.contract_id = p1_contract_id) AND (tt.request_edition.edition_id = p1_edition_id));

		RAISE NOTICE 'request_id = %', requestid;
		
		--определяем, есть ли запрос с такими данными
		IF requestid IS null THEN
			RAISE NOTICE 'request not found';
		ELSE	
			-- получение просроченности заказа
			SELECT EXTRACT(DAY FROM (CURRENT_DATE - deadline)) INTO overdue_days
			FROM tt.request
			WHERE request_id = requestid;

			IF overdue_days > 0 THEN
				-- оформление продления
				UPDATE tt.request SET deadline = deadline + overdue_days
				WHERE request_id = requestid;
				RAISE NOTICE 'Edition % was overdue by % days', p1_edition_id, overdue_days;
			END IF;
						   
			-- удаление идания из списка запрошенных
			DELETE FROM tt.request_edition
			WHERE (edition_id = p1_edition_id
				  AND request_id = requestid
			);			   
						   
			-- изменение параметров в запросе
			UPDATE tt.request SET ordered_quantity = ordered_quantity - 1,
								  returned_quantity = returned_quantity + 1
			WHERE (contract_id = p1_contract_id
				  AND request_id = requestid
			);

			-- проверка, все ли издания возвращены
			IF NOT EXISTS (
				SELECT * FROM tt.request_edition WHERE request_id = requestid
			) THEN
				-- изменение статуса запроса
				UPDATE tt.request SET order_status = 'returned' 
				WHERE (contract_id = p1_contract_id
				  AND request_id = requestid
				);
			END IF;
		END IF;
	END;
$$
language plpgsql;

COMMENT ON PROCEDURE tt.p1(integer, integer)
    IS 'Процедура 1. Оформление возврата издания
Процедура принимает номер издания и номер договора пользователя и оформляет возврат издания. Если издание было просрочено, то сначала оформляется продление и потом сразу оформляется возврат. При этом выводится информационное сообщение о том, насколько полных дней было просрочено издание. Если возвращенное издание было последним, то в запросе ставится отметка о том, что все издания были возвращены.
';

--последняя книга в запросе
--call tt.p1(1, 3);
--не последняя книга в запросе
--call tt.p1(1, 2);
--нет такого запроса
--call tt.p1(7, 7);
--просрочка
--call tt.p1(1, 1);

--Select * from tt.request
--Select * from tt.request_edition
--Select * from tt.contract
--Select * from tt.edition

drop procedure if exists tt.p3;
create procedure tt.p3()
AS $$
	DECLARE
        last_contract_date DATE;
	BEGIN
		-- пользователи, бравшие книги + их контракты
		SELECT system_user_id FROM tt.system_user u
		INNER JOIN tt.contract USING (system_user_id)
		INNER JOIN tt.request USING (system_user_id)
		WHERE ((duration = (SELECT MAX(duration) FROM tt.contract
												WHERE system_user_id = u.system_user_id)) 
        -- проверить на нужду в новом контракте (самый новый договор просрочен недавно или скоро просрочится)
			   AND ((duration + INTERVAL '28 days' >= CURRENT_DATE)
					OR (duration + INTERVAL '14 days' < CURRENT_DATE)));
		-- создать новый договор
        INSERT INTO tt.contract (system_user_id, duration, contract_date)
			VALUES (user_row.system_user_id, (CURRENT_DATE + INTERVAL 'year'), CURRENT_DATE);
		RAISE NOTICE 'user = %, create new contract until %', system_user_id, ('year' + CURRENT_DATE);
	END;
$$
language plpgsql;

COMMENT ON PROCEDURE tt.p3()
    IS 'Процедура 3. Продление договоров
Процедура предназначена для оформления новых договоров с читателями, у которых истекает текущий. Если у читателя есть истекающий договор (осталось менее 28 дней до истечения) или договор недавно истек (не более чем 14 дней назад) и нет нового договора, то оформляется новый договор срок на 1 год при условии, что читатель брал какие-нибудь книги. Если не брал никаких книг, то продление не осуществляется. Договора продлеваются для всех читателей удовлетворяющих условиям. Процедура выводит информацию о продлении.
';

--call tt.p3();

-- user 4 contract 1 договор недавно просрочился или скоро истечет и нет нового
-- user 6 contract 2 есть свежий contract 5 договор, менять не нужно
-- user 8 contract 3 договор нормальный
-- user 10 contract 4 не брал книги

--Select * from tt.system_user
--Select * from tt.contract
--Select * from tt.request