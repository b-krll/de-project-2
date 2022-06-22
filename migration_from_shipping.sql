--==================--==================
--==================--==================
--DWH: ��������� ������ ������
--==================--==================
--������
--==================--==================

--�������� ������� � �������
select * from public.shipping s limit 10;

select count(*) from public.shipping s;

--����� ���� status-�
select status, count(*) cnt 
from public.shipping s 
group by status 
order by status;

--����� ���� state-�
select state, count(*) cnt 
from public.shipping s 
group by state 
order by state;

/*
 �������� ���������� ��������� �������� � ������ shipping_country_rates �� ������, 
	��������� � shipping_country � shipping_country_base_rate, 
	�������� ��������� ���� ������� � �������� id, �� ���� �������� ������������� ������ �������. 
	����� ���� ��������� ����� ��� �id�. ���������� ������ �������� �� ���������� ��� ����� �� ������� shipping.
 */
--�� ��� ����������� ��� �����������
select shipping_country, shipping_country_base_rate 
from public.shipping s
group by shipping_country, shipping_country_base_rate;

--������ �������
drop table if exists public.shipping_country_rates;
create table shipping_country_rates (
	id serial primary key,
	shipping_country varchar(20) not null, --
	shipping_country_base_rate numeric(14,3) not null--�������� ddl shipping
	);
	
--��� ����������
select * 
from public.shipping_country_rates;

--�������� �������
insert into public.shipping_country_rates 
	(shipping_country, shipping_country_base_rate)
		select 
			shipping_country, shipping_country_base_rate 
		from public.shipping s
		group by shipping_country, shipping_country_base_rate;
		
--��������
select * 
from public.shipping_country_rates;

/*
�������� ���������� ������� �������� ������� �� �������� shipping_agreement �� ������ 
	������ vendor_agreement_description ����� ����������� :.
�������� �����:
	agreementid,
	agreement_number,
	agreement_rate,
	agreement_commission.
	Agreementid �������� ��������� ������.
	���������:
������, ��� ��� ������� regexp ������������ ��������� ��������, ������� ������� ��������������� �������� cast() , 
����� �������� ���������� �������� � ������ ��� ������� ������.
*/

--��� ����� ��������
select vendor_agreement_description 
from public.shipping s 
limit 5;

--��� ����������� �������
select count(*) all_cnt, count(vendor_agreement_description) cnt
	, count(distinct vendor_agreement_description) unq_cnt
from public.shipping s;

--������ �������
drop table if exists public.shipping_agreement;
create table public.shipping_agreement (
	agreementid bigint primary key,
	agreement_number varchar(30),
	agreement_rate numeric,
	agreement_commission numeric
	);

--��� ����������
select * 
from public.shipping_agreement;

--�������� �������

insert into public.shipping_agreement (
	agreementid, agreement_number, agreement_rate, agreement_commission)
	select distinct 
		(regexp_split_to_array(vendor_agreement_description, '\:'))[1]::bigint as agreementid,
		(regexp_split_to_array(vendor_agreement_description, '\:'))[2]::text as agreement_number,
		(regexp_split_to_array(vendor_agreement_description, '\:'))[3]::numeric as agreement_rate,
		(regexp_split_to_array(vendor_agreement_description,'\:'))[4]::numeric as agreement_commission
	from public.shipping;

--��������
select * 
from public.shipping_agreement;

select count(agreementid), count(distinct agreementid) from public.shipping_agreement;

/*
�������� ���������� � ����� �������� shipping_transfer 
�� ������ shipping_transfer_description ����� ����������� :.
�������� �����:
transfer_type,
transfer_model,
shipping_transfer_rate .
�������� ��������� ���� ������� � �������� id. 
���������: ����� ������� ��� ����������� ������ ����� ������� 
��� ��������� ������������� ����� � ���� numeric(). 
��������, ���� shipping_transfer_rate ����� 2.5%, �� ��� �������� � ��� numeric(14,2)
� ��� ���������� 0,5%.
*/

--��� ����� ��������
select distinct shipping_transfer_description, shipping_transfer_rate
from public.shipping s 
order by 1
limit 500;

--��� ����������� �������
select count(*) all_cnt, count(shipping_transfer_description) cnt
	, count(distinct shipping_transfer_description) unq_cnt
from public.shipping s;

--������ �������
drop table if exists public.shipping_transfer;
create table public.shipping_transfer (
	id serial primary key,
	transfer_type varchar(2),
	transfer_model varchar(20),
	shipping_transfer_rate numeric(14,3)
	);
	
--��� ��������
select * from public.shipping_transfer;

--������� �������
insert into public.shipping_transfer(
	transfer_type, transfer_model, shipping_transfer_rate)
	select 
		(regexp_split_to_array(shipping_transfer_description,'\:'))[1]::varchar as transfer_type,
		(regexp_split_to_array(shipping_transfer_description,'\:'))[2]::varchar as transfer_model,
		shipping_transfer_rate
	from public.shipping 
	group by transfer_type, transfer_model, shipping_transfer_rate;
	
--�������
select * from public.shipping_transfer;


/*
�������� ������� shipping_info � ����������� ���������� shippingid 
� ������� � � ���������� ������������� shipping_country_rates, 
shipping_agreement, shipping_transfer � ����������� ����������� 
� �������� shipping_plan_datetime , payment_amount , vendorid .
���������:
C���� � ����� ���������-������������� ����� ������ �������� ������� 
� ��� ��������� ����������� ������ ������ � ������� �, ���� ��������� ������ ������ � �������.
�� ��� ������� ��������������, ����� ��������� ����������� shipping_transfer � shipping_country_rates.
������ ���������� ����� ������ ���������� �� shipping, ������� JOIN � ���� ���� �������� � �������� �������������� ��� ��������.
*/

--�� ������ ���� ����� ������� �������
select --*
	shippingid, shipping_plan_datetime, payment_amount, vendorid
from public.shipping s 
order by shippingid
limit 10;

--��� �����������
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from public.shipping s;

--
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from (
	select distinct shippingid, shipping_plan_datetime, payment_amount, vendorid
	from public.shipping) s;
	
--������ �������
drop table if exists public.shipping_info;
create table shipping_info (
	shippingid bigint primary key, --��������� ������������
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
	
--��������
select * from public.shipping_info;

--�������� ���� ��� ����� �������� � �������
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

--������� �������
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

--��������
select * from public.shipping_info;

--��������
select count(*) all_cnt, count(shippingid) cnt
	, count(distinct shippingid) unq_cnt
from public.shipping_info;

/*
�������� ������� �������� � �������� shipping_status � �������� ���� ���������� �� ���� shipping (status , state).
�������� ���� ���������� ���������� �� ������������ ������� �������� 
	shipping_start_fact_datetime
	, shipping_end_fact_datetime 
. �������� ��� ������� ����������� shippingid ��� �������� ��������� ��������.
���������:
������ � ������� ������ �������� ������������ status � state �� ������������� ������� ���� state_datetime � ������� shipping.
shipping_start_fact_datetime � ��� ����� state_datetime, ����� state ������ ������� � ��������� booked.
shipping_end_fact_datetime � ��� ����� state_datetime , ����� state ������ ������� � ��������� received.
������ ������������ �������� with ��� ���������� ��������� �������
, ������ ��� ����� ��������� ���������� �� shippingid � ������������� �������� state_datetime. 
����� ��� ������ ���������� � shipping_status ����� ������� JOIN � ��������� ������� ������� �������.
*/

--�� ��� �����������
select distinct shippingid, state_datetime, status, state
	, row_number() over (partition by shippingid order by state_datetime desc) num
from public.shipping s 
order by shippingid 
limit 60;

--������� ����� id, ������� ��������, ������� ��������
select count(distinct shippingid) shippingid_uniq
	, count((case when state = 'booked' then shippingid end)) as booked
	, count(distinct (case when state = 'booked' then shippingid end)) as booked_uniq
	, count((case when state = 'recieved' then shippingid end)) as recieved
	, count(distinct (case when state = 'recieved' then shippingid end)) as recieved_uniq
from public.shipping;

--��� ���� � ��������
select count(distinct shippingid)
from public.shipping
where state = 'returned';

--
select distinct shippingid
from public.shipping
where state = 'returned'
order by 1;

--������ �� ������ state = booked
select distinct status, state
from (
	select distinct shippingid, state_datetime, status, state
		, row_number() over (partition by shippingid order by state_datetime) num
 from public.shipping s ) t 
 where num::int = 1;
--booked ������ ������� �� �������

--��������� state
select distinct status, state
from (
	select distinct shippingid, state_datetime, status, state
		, row_number() over (partition by shippingid order by state_datetime desc) num
 from public.shipping s ) t 
 where num::int = 1;

--��� ��������� ������� - ������� ������� ��������� �������� ��� ���������
--� ������ ������� received
--shipping_end_fact_datetime ������� �������� received ��� ������������ �������� �� returned

select distinct shippingid, state_datetime, status, state
	, row_number() over (partition by shippingid order by state_datetime desc) num
from public.shipping s 
where state <> 'returned'
order by shippingid 
limit 60;

--������ �������
drop table if exists public.shipping_status;
create table public.shipping_status (
	shippingid bigint primary key, 
	status varchar(20), 
	state varchar(20), 
	shipping_start_fact_datetime timestamp, 
	shipping_end_fact_datetime timestamp
	);

--��������
select * from public.shipping_status;

--��� ���� ��������� �������
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

--�������� �������
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

--�������
select *
from public.shipping_status
order by shippingid;