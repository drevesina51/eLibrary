/*	1.	Топ авторов по книгам
	Отчет представить в виде:
	автор,
	количество написанных изданий,
	количество соавторов,
	количество написанных книг в соавторстве.
*/

WITH s1 AS(
	SELECT  author_id,
			name,
			surname,
			COUNT(edition_id) AS works
	FROM tt.author
	INNER JOIN tt.author_edition USING (author_id)	
	GROUP BY author_id
	ORDER BY works DESC
), s2 AS(
	SELECT  qwe.a1 AS author_id,
			COUNT(qwe.a2) AS coauthors
	FROM
	(SELECT DISTINCT a.author_id AS a1,
				b.author_id AS a2
				--COUNT(b.author_id)	AS coauthors	
		FROM tt.author_edition a
		INNER JOIN tt.author_edition b USING (edition_id)
			WHERE (a.author_id != b.author_id)
		GROUP BY a.author_id, b.author_id
		ORDER BY a.author_id) AS qwe
	GROUP BY qwe.a1
), s3 AS(
	SELECT  qwe.a1 AS author_id,
			COUNT(edition_id) AS works_in_party
	FROM
	(SELECT DISTINCT ON (a.author_id, edition_id)
	 			a.author_id AS a1,
				b.author_id AS a2,
				edition_id
				--COUNT(b.author_id)	AS coauthors	
		FROM tt.author_edition a
		INNER JOIN tt.author_edition b USING (edition_id)
			WHERE (a.author_id != b.author_id)
		GROUP BY a.author_id, b.author_id, edition_id
		ORDER BY a.author_id) AS qwe
	GROUP BY qwe.a1
)
SELECT author_id, name, surname, works, coauthors, works_in_party FROM s1
INNER JOIN s2 USING (author_id)
INNER JOIN s3 USING (author_id)
ORDER BY works DESC;

/*  2.	Получить информацию о читателях, имеющих максимальную задолженность среди всех. Отчет представить в виде:
	Имя читателя s1, s2;
	число договоров у читателя за все время, s1;
	признак наличия актуального договора (есть / нет), s1;
	номер текущего договора, s1;
	срок действия текущего договора, s1;
	общее количество запросов, s3;
	количество запросов с нарушениями, s2;
	число текущих просроченных книг, s2.
	s1 - all contracts and requests; s2 - overdated requests
*/
WITH s1 AS(
	SELECT  system_user_id,
			name,
			CASE WHEN MAX(duration) >= CURRENT_DATE THEN 'yes' ELSE 'no' END AS has_contract,
			MAX(duration) AS contract_duration,
			COUNT(contract_id) AS contract_amount
	FROM tt.system_user su
	INNER JOIN tt.contract USING (system_user_id)	
	GROUP BY system_user_id
), s2 AS(
	SELECT	su.system_user_id,
			COUNT(request_id) AS violations_quantity,
			SUM(ordered_quantity) AS overdue_books
	FROM tt.system_user su
	INNER JOIN tt.contract USING (system_user_id)
	INNER JOIN tt.request USING (contract_id)
	WHERE deadline < CURRENT_DATE
	GROUP BY su.system_user_id
), s3 AS(
	SELECT  su.system_user_id,
			COUNT(request_id) AS request_amount
	FROM tt.system_user su
	INNER JOIN tt.contract USING (system_user_id)
	INNER JOIN tt.request USING (contract_id)	
	GROUP BY su.system_user_id
)
SELECT system_user_id, name, contract_amount, has_contract, contract_id AS current_contract_id,
		contract_duration, request_amount, violations_quantity, overdue_books FROM s1
INNER JOIN s2 USING (system_user_id)
INNER JOIN s3 USING (system_user_id)
INNER JOIN tt.contract USING (system_user_id)
WHERE contract_id = (SELECT contract_id FROM tt.contract WHERE duration = contract_duration)
AND overdue_books = (SELECT MAX(overdue_books) FROM s2);

/*	3.	Получить статистику по популярности изданий разрных разделов по месяцам прошлого года. Отчет получить в виде 12 строк с информацией для каждого месяца:
Название месяца;
название самого популярного раздела (издания из которого чаще всего брали);
самая популярная книга в этом разделе в заданном месяце;
кол-во запросов по данному разделу в месяце;
количество запросов в этом разделе во всем прошлом году;
кол-во запросов на самую популярную книгу в этом месяце;
дата последнего запроса на данную книгу в этом месяце.
*/



/*  4.	Получить информацию о читателях с несколькими договорами. Отчет представить в виде:
Имя читателя s1,
число оформленных договоров s1,
дата оформления первого договора s1,
дата окончания последнего договора s1,
общее количество заказанной литературы по всем договорам читателя s1,
количество просроченных изданий s2,
--название самого популярного издания у читателя s2,
признак есть или нет активный договор s1.
*/

WITH s1 AS(
	SELECT  su.system_user_id,
			name,
			CASE WHEN MAX(duration) >= CURRENT_DATE THEN 'yes' ELSE 'no' END AS has_contract,
			MAX(duration) AS max_contract_duration,
			MIN(contract_date) AS first_contract_date,
			COUNT(contract_id) AS contract_amount
	
	FROM tt.system_user su
	INNER JOIN tt.contract USING (system_user_id)	
	GROUP BY su.system_user_id
	HAVING COUNT(contract_id) > 1
), s2 AS(
	SELECT	su.system_user_id,
			SUM(ordered_quantity) AS overdue_books
	FROM tt.system_user su
	INNER JOIN tt.contract USING (system_user_id)
	INNER JOIN tt.request USING (contract_id)
	WHERE deadline < CURRENT_DATE
	GROUP BY su.system_user_id
), s3 AS(
	SELECT  su.system_user_id,
			SUM(ordered_quantity) AS ordered_quantity
	FROM tt.system_user su
	INNER JOIN tt.request USING (system_user_id)	
	GROUP BY su.system_user_id
), s4 AS(
	SELECT DISTINCT ON (system_user_id)
			system_user_id,
			edition_id,
			title AS popular,
			COUNT(edition_id) AS count
	FROM tt.system_user
	INNER JOIN tt.request USING (system_user_id)
	INNER JOIN tt.request_edition USING (request_id)
	INNER JOIN tt.edition USING(edition_id)
	GROUP BY system_user_id, edition_id, title
	ORDER BY system_user_id, count DESC
)
SELECT system_user_id, name, contract_amount, first_contract_date, edition_id, COALESCE(popular, 'none') AS popular,
		max_contract_duration, COALESCE(ordered_quantity, 0) AS ordered_quantity, COALESCE(overdue_books, 0) AS overdue_books, has_contract FROM s1
LEFT JOIN s2 USING (system_user_id)
LEFT JOIN s3 USING (system_user_id)
LEFT JOIN s4 USING (system_user_id)
GROUP BY system_user_id, contract_amount, name, first_contract_date, edition_id,
		 popular, max_contract_duration, ordered_quantity, overdue_books, has_contract;

/*  5.	Получить информацию о соавторстве авторов.
Результат имеет N строк и N+1 столбец, где один столбец – имя автора,
а остальные содержат в себе число, сколько раз автор из строки был в соавторстве с автором из столбца.
Для вывода в таком виде гуглить “sql transpose table”, “sql crosstab”, “sql pivot”.
*/
--create extension tablefunc;

CREATE OR REPLACE FUNCTION tt.string() RETURNS varchar(50) AS $$
DECLARE
    colnames varchar(200);
BEGIN
    EXECUTE 'SELECT STRING_AGG(CONCAT(author_id,  '' bigint''), '','') FROM tt.author' INTO colnames;
	RETURN colnames;
END;
$$ LANGUAGE plpgsql;
SELECT tt.string()

SELECT * FROM crosstab (
	$$WITH s1 AS (SELECT  a.author_id AS author1,
		b.author_id AS author2,
		COUNT(edition_id) AS coop_works
		FROM tt.author_edition a
		INNER JOIN tt.author_edition b USING (edition_id)
		WHERE (a.author_id != b.author_id)
		GROUP BY a.author_id, b.author_id
		ORDER BY a.author_id
	)
	SELECT q.author_id AS author_1, w.author_id AS author_2, COALESCE(coop_works, 0) AS coop_works FROM tt.author q
	CROSS JOIN tt.author w
	LEFT JOIN s1 ON (q.author_id = author1 AND w.author_id = author2)$$
) --AS sours_table(author_id integer, q1 bigint, q2 bigint, q3 bigint, q4 bigint, q5 bigint, q6 bigint, q7 bigint)
AS sours_table(' + tt.string() + ')

SELECT STRING_AGG(CONCAT(author_id,  ' bigint'), ',') AS tmp FROM tt.author


SELECT * FROM crosstab (
	$$WITH s1 AS (SELECT  a.author_id AS author1,
		b.author_id AS author2,
		COUNT(edition_id) AS coop_works
		FROM tt.author_edition a
		INNER JOIN tt.author_edition b USING (edition_id)
		WHERE (a.author_id != b.author_id)
		GROUP BY a.author_id, b.author_id
		ORDER BY a.author_id
	), s2(
		SELECT STRING_AGG(CONCAT(author_id,  ' bigint'), ',') AS string FROM tt.author
	)
	SELECT q.author_id AS author_1, w.author_id AS author_2, COALESCE(coop_works, 0) AS coop_works FROM tt.author q
	CROSS JOIN tt.author w
	LEFT JOIN s1 ON (q.author_id = author1 AND w.author_id = author2)$$
) --AS sours_table(author_id integer, q1 bigint, q2 bigint, q3 bigint, q4 bigint, q5 bigint, q6 bigint, q7 bigint)
AS sours_table(author_id integer, STRING_AGG(CONCAT(author_id,  ' bigint'), ','))