drop table if exists tt.author;
drop table if exists tt.author_edition;
drop table if exists tt.contract;
drop table if exists tt.edition;
drop table if exists tt.payment_document;
drop table if exists tt.receipt_edition;
drop table if exists tt.receipt_document;
drop table if exists tt.rejection;
drop table if exists tt.rejection_edition;
drop table if exists tt.request;
drop table if exists tt.request_edition;
drop table if exists tt.role;
drop table if exists tt.section;
drop table if exists tt.section_edition;
drop table if exists tt.subscribe;
drop table if exists tt.system_user;
drop table if exists tt.write_off_document;
drop table if exists tt.write_off_edition;

CREATE TABLE tt.author (
    author_id serial NOT NULL PRIMARY KEY,
    name character varying(50) NOT NULL,
    surname character varying(50) NOT NULL,
    patronymic character varying(50),
    research_sphere character varying(50),
    academic_degree character varying(50)
);

CREATE TABLE tt.role (
    role_id serial NOT NULL PRIMARY KEY,
    role_name character varying(50) NOT NULL
);

CREATE TABLE tt.system_user (
    system_user_id serial NOT NULL PRIMARY KEY,
    role_id integer NOT NULL REFERENCES tt.role,
    admin_id integer,
    name character varying(50) NOT NULL,
    surname character varying(50) NOT NULL,
    patronymic character varying(50),
    account_name character varying(50) NOT NULL,
    login character varying(50) NOT NULL,
    password character varying(50) NOT NULL,
    registration_date date NOT NULL,
    FOREIGN KEY (admin_id) REFERENCES tt.system_user (system_user_id)
);

CREATE TABLE tt.contract (
    contract_id serial NOT NULL PRIMARY KEY,
    system_user_id integer NOT NULL REFERENCES tt.system_user,
    duration date NOT NULL,
    contract_text character varying(50) NOT NULL,
    contract_date date NOT NULL
);

CREATE TABLE tt.edition (
    edition_id serial NOT NULL PRIMARY KEY,
    books_quantity integer NOT NULL,
    title character varying(50) NOT NULL,
    annotation character varying(50)
);

CREATE TABLE tt.payment_document (
    payment_document_id serial NOT NULL PRIMARY KEY,
    contract_id integer NOT NULL REFERENCES tt.contract,
    document_text character varying(50)
);

CREATE TABLE tt.receipt_document (
    receipt_document_id serial NOT NULL PRIMARY KEY,
    system_user_id integer NOT NULL REFERENCES tt.system_user,
    admision_date date NOT NULL,
    ordered_quantity integer NOT NULL
);

CREATE TABLE tt.rejection (
    rejection_id serial NOT NULL PRIMARY KEY,
    contract_id integer NOT NULL REFERENCES tt.contract,
    ordered_quantity integer NOT NULL,
    reason character varying(50) NOT NULL
);

CREATE TABLE tt.request (
    request_id serial NOT NULL PRIMARY KEY,
    system_user_id integer NOT NULL REFERENCES tt.system_user,
    contract_id integer NOT NULL REFERENCES tt.contract,
    deadline date NOT NULL,
    ordered_quantity integer NOT NULL,
    returned_quantity integer NOT NULL,
    order_status character varying(50) NOT NULL
);

CREATE TABLE tt.section (
    section_id serial NOT NULL PRIMARY KEY,
    main_section_id integer,
    month_price integer NOT NULL,
    title character varying(50) NOT NULL,
    section_summary character varying(50),
    FOREIGN KEY (main_section_id) REFERENCES tt.section (section_id)
);

CREATE TABLE tt.subscribe (
    subscribe_id serial NOT NULL PRIMARY KEY,
    contract_id integer NOT NULL REFERENCES tt.contract,
    payment_document_id integer NOT NULL REFERENCES tt.payment_document,
    deadline date NOT NULL,
    section_id integer NOT NULL REFERENCES tt.section
);

CREATE TABLE tt.write_off_document (
    write_off_document_id serial NOT NULL PRIMARY KEY,
    system_user_id integer NOT NULL REFERENCES tt.system_user,
    write_off_date date NOT NULL,
    reason character varying(50) NOT NULL,
    ordered_quantity integer NOT NULL
);

CREATE TABLE tt.write_off_edition (
    write_off_document_id integer NOT NULL REFERENCES tt.write_off_document,
    edition_id integer NOT NULL REFERENCES tt.edition,
    comment character varying(50),
    PRIMARY KEY(write_off_document_id, edition_id)
);

CREATE TABLE tt.author_edition (
    author_id integer NOT NULL REFERENCES tt.author,
    edition_id integer NOT NULL REFERENCES tt.edition,
    comment character varying(50),
    PRIMARY KEY(author_id, edition_id)
);

CREATE TABLE tt.receipt_edition (
    receipt_document_id integer NOT NULL REFERENCES tt.receipt_document,
    edition_id integer NOT NULL REFERENCES tt.edition,
    comment character varying(50),
    PRIMARY KEY(receipt_document_id, edition_id)
);

CREATE TABLE tt.rejection_edition (
    rejection_id integer NOT NULL REFERENCES tt.rejection,
    edition_id integer NOT NULL REFERENCES tt.edition,
    comment character varying(50) NOT NULL,
    PRIMARY KEY(rejection_id, edition_id)
);

CREATE TABLE tt.request_edition (
    request_id integer NOT NULL REFERENCES tt.request,
    edition_id integer NOT NULL REFERENCES tt.edition,
    comment character varying(50),
    PRIMARY KEY(request_id, edition_id)
);

CREATE TABLE tt.section_edition (
    section_id integer NOT NULL REFERENCES tt.section,
    edition_id integer NOT NULL REFERENCES tt.edition,
    comment character varying(50),
    PRIMARY KEY(section_id, edition_id)
);

INSERT INTO tt.role (role_id, role_name) VALUES
(1, 'reader'),
(2, 'librarian'),
(3, 'administrator');

INSERT INTO tt.system_user (role_id, admin_id, name, surname, patronymic, account_name, login, password, registration_date) VALUES 
(3, NULL, 'Roman', 'Samorodov', 'Alekseevich', 'roman_acc', 'roman_log', 'roman_pass', '2023-01-01'),
(2, 1, 'Vasiliy', 'Pupkin', NULL, 'vasiliy_acc', 'vasiliy_log', 'vasiliy_pass', '2023-01-02'),
(2, 1, 'Rostislav', 'Berezhnoy', NULL, 'rostislav_acc', 'rostislav_log', 'rostislav_pass', '2023-01-03'),
(1, NULL, 'Almaz', 'Idiyatulin', NULL, 'almaz_acc', 'almaz_log', 'almaz_pass', '2023-01-04'),
(1, NULL, 'Vera', 'Fedotova', NULL, 'vera_acc', 'vera_log', 'vera_pass', '2023-01-05'),
(1, NULL, 'Arthur', 'Zakirov', NULL, 'arthur_acc', 'arthur_log', 'arthur_pass', '2023-01-06'),
(1, NULL, 'Anna', 'Kuchebo', NULL, 'anna_acc', 'anna_log', 'anna_pass', '2023-01-07'),
(1, NULL, 'Ivan', 'Hramov', NULL, 'ivan_acc', 'ivan_log', 'ivan_pass', '2023-01-08'),
(1, NULL, 'Max', 'Udalov', NULL, 'max_acc', 'max_log', 'max_pass', '2023-01-09'),
(1, NULL, 'Misha', 'Nazarko', NULL, 'misha_acc', 'misha_log', 'misha_pass', '2023-01-10');

INSERT INTO tt.author (name, surname, patronymic, research_sphere, academic_degree) VALUES
('Lev', 'Tolstoy', 'Nikolaevich', NULL, NULL),
('Elon', 'Reeve', 'Mask', 'space travel', 'scientist'),
('author1', 'Ananas', NULL, NULL, NULL),
('author2', 'Kakos', NULL, NULL, NULL);

INSERT INTO tt.edition (books_quantity, title) VALUES
(15, 'War and Peace'),
(10, 'Space in human life'),
(20, 'Textbook on higher mathematics'),
(8, 'Cooking on fire'),
(30, 'Anna Karenina'),
(18, 'Home cooking'),
(25, 'Cooking in a steamer');


INSERT INTO tt.author_edition (author_id, edition_id, comment) VALUES
(1, 4, 'Lev - Anna Karenina'),
(1, 1, 'Lev - War and Peace'),
(2, 2, 'Elon - Space in human life'),
(3, 6, 'Author 1 - Сooking in a steamer'),
(3, 3, 'Author 1 - Textbook on higher mathematics'),
(3, 2, 'Author 1 - Space in human life'),
(4, 5, 'Author 2 - Cooking on fire'),
(4, 3, 'Author 2 - Textbook on higher mathematics');

INSERT INTO tt.contract (system_user_id, duration, contract_text, contract_date) VALUES
(4, '2030-01-04', 'contract text about smth important', '2023-02-04'),
(6, '2030-01-06', 'contract text about smth important', '2023-02-06'),
(8, '2030-01-08', 'contract text about smth important', '2023-02-08'),
(10, '2030-01-10', 'contract text about smth important', '2023-02-10');

INSERT INTO tt.payment_document (contract_id, document_text) VALUES
(1, 'Payment document text about smth important'),
(3, 'Payment document text about smth important');

INSERT INTO tt.section (main_section_id, month_price, title) VALUES
(NULL, 100, 'Classic'),
(NULL, 200, 'Scientific literature'),
(2, 120, 'Space');

INSERT INTO tt.section_edition (section_id, edition_id) VALUES 
(1, 1),
(3, 2),
(2, 3),
(1, 4);

INSERT INTO tt.subscribe (contract_id, payment_document_id, deadline, section_id) VALUES
(1, 1, '2023-01-03', 1),
(3, 2, '2023-03-04', 2),
(3, 2, '2023-03-04', 1);
