--==================--==================
--==================--==================
--DWH: Пересмотр модели данных
--==================--==================
--Проект
--==================--==================

--исходная таблица с данными
select * from public.shipping s limit 10;

select count(*) from public.shipping s;

--какие есть status-ы
select status, count(*) cnt 
from public.shipping s 
group by status 
order by status;

--какие есть state-ы
select state, count(*) cnt 
from public.shipping s 
group by state 
order by state;

/*
 Создайте справочник стоимости доставки в страны shipping_country_rates из данных, 
	указанных в shipping_country и shipping_country_base_rate, 
	сделайте первичный ключ таблицы — серийный id, то есть серийный идентификатор каждой строчки. 
	Важно дать серийному ключу имя «id». Справочник должен состоять из уникальных пар полей из таблицы shipping.
 */
--то что потребуется для справочника
select shipping_country, shipping_country_base_rate 
from public.shipping s
group by shipping_country, shipping_country_base_rate;

--создаю таблицу
drop table if exists public.shipping_country_rates;
create table shipping_country_rates (
	id serial primary key,
	shipping_country varchar(20) not null, --
	shipping_country_base_rate numeric(14,3) not null--согласно ddl shipping
	);
	
--что получилось
select * 
from public.shipping_country_rates;

--пополняю таблицу
insert into public.shipping_country_rates 
	(shipping_country, shipping_country_base_rate)
		select 
			shipping_country, shipping_country_base_rate 
		from public.shipping s
		group by shipping_country, shipping_country_base_rate;
		
--проверяю
select * 
from public.shipping_country_rates;

/*
Создайте справочник тарифов доставки вендора по договору shipping_agreement из данных 
	строки vendor_agreement_description через разделитель :.
Названия полей:
	agreementid,
	agreement_number,
	agreement_rate,
	agreement_commission.
	Agreementid сделайте первичным ключом.
	Подсказка:
Учтите, что при функции regexp возвращаются строковые значения, поэтому полезно воспользоваться функцией cast() , 
чтобы привести полученные значения в нужный для таблицы формат.
*/

--что нужно добавить
select vendor_agreement_description 
from public.shipping s 
limit 5;

--как заполняется столбец
select count(*) all_cnt, count(vendor_agreement_description) cnt
	, count(distinct vendor_agreement_description) unq_cnt
from public.shipping s;

--создаю таблицу
drop table if exists public.shipping_agreement;
create table public.shipping_agreement (
	agreementid bigint primary key,
	agreement_number varchar(30),
	agreement_rate numeric,
	agreement_commission numeric
	);

--что получилось
select * 
from public.shipping_agreement;

--пополняю таблицу

insert into public.shipping_agreement (
	agreementid, agreement_number, agreement_rate, agreement_commission)
	select distinct 
		(regexp_split_to_array(vendor_agreement_description, '\:'))[1]::bigint as agreementid,
		(regexp_split_to_array(vendor_agreement_description, '\:'))[2]::text as agreement_number,
		(regexp_split_to_array(vendor_agreement_description, '\:'))[3]::numeric as agreement_rate,
		(regexp_split_to_array(vendor_agreement_description,'\:'))[4]::numeric as agreement_commission
	from public.shipping;

--проверка
select * 
from public.shipping_agreement;

select count(agreementid), count(distinct agreementid) from public.shipping_agreement;

/*
Создайте справочник о типах доставки shipping_transfer 
из строки shipping_transfer_description через разделитель :.
Названия полей:
transfer_type,
transfer_model,
shipping_transfer_rate .
Сделайте первичный ключ таблицы — серийный id. 
Подсказка: Важно помнить про размерность знаков после запятой 
при выделении фиксированной длины в типе numeric(). 
Например, если shipping_transfer_rate равен 2.5%, то при миграции в тип numeric(14,2)
у вас отбросится 0,5%.
*/

--что нужно добавить
select distinct shipping_transfer_description, shipping_transfer_rate
from public.shipping s 
order by 1
limit 500;

--как заполняется столбец
select count(*) all_cnt, count(shipping_transfer_description) cnt
	, count(distinct shipping_transfer_description) unq_cnt
from public.shipping s;

--создаю таблицу
drop table if exists public.shipping_transfer;
create table public.shipping_transfer (
	id serial primary key,
	transfer_type varchar(2),
	transfer_model varchar(20),
	shipping_transfer_rate numeric(14,3)
	);
	
--как выглядит
select * from public.shipping_transfer;

--пополню таблицу
insert into public.shipping_transfer(
	transfer_type, transfer_model, shipping_transfer_rate)
	select 
		(regexp_split_to_array(shipping_transfer_description,'\:'))[1]::varchar as transfer_type,
		(regexp_split_to_array(shipping_transfer_description,'\:'))[2]::varchar as transfer_model,
		shipping_transfer_rate
	from public.shipping 
	group by transfer_type, transfer_model, shipping_transfer_rate;
	
--проверю
select * from public.shipping_transfer;


/*
Создайте таблицу shipping_info с уникальными доставками shippingid 
и свяжите её с созданными справочниками shipping_country_rates, 
shipping_agreement, shipping_transfer и константной информацией 
о доставке shipping_plan_datetime , payment_amount , vendorid .
Подсказки:
Cвязи с тремя таблицами-справочниками лучше делать внешними ключами 
— это обеспечит целостность модели данных и защитит её, если нарушится логика записи в таблицы.
Вы уже сделали идентификаторы, когда создавали справочники shipping_transfer и shipping_country_rates.
Теперь достаточно взять нужную информацию из shipping, сделать JOIN к этим двум таблицам и получить идентификаторы для миграции.
*/

--на основе чего будет создана таблица
select --*
	shippingid, shipping_plan_datetime, payment_amount, vendorid
from public.shipping s 
order by shippingid
limit 10;

--как заполняется
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from public.shipping s;

--
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from (
	select distinct shippingid, shipping_plan_datetime, payment_amount, vendorid
	from public.shipping) s;
	
--создаю таблицу
drop table if exists public.shipping_info;
create table shipping_info (
	shippingid bigint primary key, --поддержка уникальности
	shipping_plan_datetime timestamp, 
	payment_amount numeric(14,2), 
	vendorid bigint,
	shipping_country_id bigint, 
	agreementid bigint,
	transfer_type_id bigint,
	foreign key (shipping_country_id) references public.shipping_country_rates(id) on update cascade,
	foreign key (agreementid) references public.shipping_agreement(agreementid) on update cascade,
	foreign key (transfer_type_id) references public.shipping_transfer(id) on update cascade
	);
	
--проверяю
select * from public.shipping_info;

--проверка того что будут заливать в таблицу
with t as (
		select distinct s.shippingid, s.shipping_plan_datetime, s.payment_amount, s.vendorid,
			scr.id as shipping_country_id,
			sa.agreementid,
			st.id as transfer_type_id
		from public.shipping s
		join public.shipping_country_rates scr on s.shipping_country = scr.shipping_country
		join public.shipping_agreement sa 
			on (regexp_split_to_array(s.vendor_agreement_description, '\:'))[1]::bigint = sa.agreementid
		join public.shipping_transfer st 
			on s.shipping_transfer_description = (st.transfer_type||':'||st.transfer_model) 
			)
		select count(*) all_cnt, count(shippingid) cnt, count(distinct shippingid) unq_cnt
		from t;

--пополню таблицу
insert into public.shipping_info(
	shippingid, shipping_plan_datetime, payment_amount, vendorid, shipping_country_id, agreementid, transfer_type_id
	)
	with t as (
		select distinct s.shippingid, s.shipping_plan_datetime, s.payment_amount, s.vendorid,
			scr.id as shipping_country_id,
			sa.agreementid,
			st.id as transfer_type_id
		from public.shipping s
		join public.shipping_country_rates scr on s.shipping_country = scr.shipping_country
		join public.shipping_agreement sa 
			on (regexp_split_to_array(s.vendor_agreement_description, '\:'))[1]::bigint = sa.agreementid
		join public.shipping_transfer st 
			on s.shipping_transfer_description = (st.transfer_type||':'||st.transfer_model) 
			)
	select 
		shippingid::bigint, shipping_plan_datetime::timestamp, payment_amount::numeric(14,2)
		, vendorid::bigint, shipping_country_id::bigint, agreementid::bigint, transfer_type_id::bigint
	from t;

--проверяю
select * from public.shipping_info;

--проверяю
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from public.shipping_info;

/*
Создайте таблицу статусов о доставке shipping_status и включите туда информацию из лога shipping (status , state).
Добавьте туда вычислимую информацию по фактическому времени доставки 
	shipping_start_fact_datetime
	, shipping_end_fact_datetime 
. Отразите для каждого уникального shippingid его итоговое состояние доставки.
Подсказки:
Данные в таблице должны отражать максимальный status и state по максимальному времени лога state_datetime в таблице shipping.
shipping_start_fact_datetime — это время state_datetime, когда state заказа перешёл в состояние booked.
shipping_end_fact_datetime — это время state_datetime , когда state заказа перешёл в состояние received.
Удобно использовать оператор with для объявления временной таблицы
, потому что можно сохранить информацию по shippingid и максимальному значению state_datetime. 
Далее при записи информации в shipping_status можно сделать JOIN и дополнить таблицу нужными данными.
*/

--то что потребуется
select distinct shippingid, state_datetime, status, state
	, row_number() over (partition by shippingid order by state_datetime desc) num
from public.shipping s 
order by shippingid 
limit 60;

--сколько всего id, сколько заказано, сколько получено
select count(distinct shippingid) shippingid_uniq
	, count((case when state = 'booked' then shippingid end)) as booked
	, count(distinct (case when state = 'booked' then shippingid end)) as booked_uniq
	, count((case when state = 'recieved' then shippingid end)) as recieved
	, count(distinct (case when state = 'recieved' then shippingid end)) as recieved_uniq
from public.shipping;

--еще есть и возвраты
select count(distinct shippingid)
from public.shipping
where state = 'returned';

--
select distinct shippingid
from public.shipping
where state = 'returned'
order by 1;

--всегда ли первый state = booked
select distinct status, state
from (
	select distinct shippingid, state_datetime, status, state
		, row_number() over (partition by shippingid order by state_datetime) num
 from public.shipping s ) t 
 where num::int = 1;
--booked первое событие по времени

--последние state
select distinct status, state
from (
	select distinct shippingid, state_datetime, status, state
		, row_number() over (partition by shippingid order by state_datetime desc) num
 from public.shipping s ) t 
 where num::int = 1;

--тут возникает дилемма - считать возврат последним событием или получение
--в задаче указано received
--shipping_end_fact_datetime заполню временем received или максимальным отличным от returned

select distinct shippingid, state_datetime, status, state
	, row_number() over (partition by shippingid order by state_datetime desc) num
from public.shipping s 
where state <> 'returned'
order by shippingid 
limit 60;

--создаю таблицу
drop table if exists public.shipping_status;
create table public.shipping_status (
	shippingid bigint primary key, 
	status varchar(20), 
	state varchar(20), 
	shipping_start_fact_datetime timestamp, 
	shipping_end_fact_datetime timestamp
	);

--проверка
select * from public.shipping_status;

--как буду заполнять таблицу
with fin as (
	select distinct shippingid, state_datetime, status, state
		, row_number() over (partition by shippingid order by state_datetime desc) num
	from public.shipping s 
	where state <> 'returned'),
fin_sh as (
select --*--count(*)
	distinct t.shippingid
	, t.status::varchar as status
	, t.state::varchar as state
	, t1.state_datetime::timestamp as shipping_start_fact_datetime
	, t.state_datetime::timestamp as shipping_end_fact_datetime
from fin t
join fin t1 on t.shippingid = t1.shippingid
	and t1.state = 'booked'
where t.num::int = 1
--order by 1
	)
select --count(shippingid), count(distinct shippingid) shippingid_uniq
	*
from fin_sh
order by 1;

--заполняю таблицу
insert into public.shipping_status (
	shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
	with fin as (
		select distinct shippingid, state_datetime, status, state
			, row_number() over (partition by shippingid order by state_datetime desc) num
		from public.shipping s 
		where state <> 'returned'),
	fin_sh as (
		select 
			distinct t.shippingid
			, t.status::varchar as status
			, t.state::varchar as state
			, t1.state_datetime::timestamp as shipping_start_fact_datetime
			, t.state_datetime::timestamp as shipping_end_fact_datetime
		from fin t
		join fin t1 on t.shippingid = t1.shippingid
			and t1.state = 'booked'
		where t.num::int = 1
		)
	select shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime
	from fin_sh;

--проверю
select *
from public.shipping_status
order by shippingid;