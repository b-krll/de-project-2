--==================--==================
--==================--==================
--DWH: ѕересмотр модели данных
--==================--==================
--ѕроект
--==================--==================
--DDL таблиц
--==================--==================

--drop table if exists public.shipping_info;
--drop table if exists public.shipping_country_rates;
--drop table if exists public.shipping_agreement;
--drop table if exists public.shipping_transfer;
--drop table if exists public.shipping_status;

--создаю таблицу shipping_country_rates
drop table if exists public.shipping_country_rates;
create table shipping_country_rates (
	id serial primary key,
	shipping_country varchar(20) not null, --
	shipping_country_base_rate numeric(14,3) not null--согласно ddl shipping
	);
	
--создаю таблицу shipping_agreement
drop table if exists public.shipping_agreement;
create table public.shipping_agreement (
	agreementid bigint primary key,
	agreement_number varchar(30),
	agreement_rate numeric(14,2),
	agreement_commission numeric(14,2)
	);

--создаю таблицу shipping_transfer
drop table if exists public.shipping_transfer;
create table public.shipping_transfer (
	id serial primary key,
	transfer_type varchar(2),
	transfer_model varchar(20),
	shipping_transfer_rate numeric(14,3)
	);
	
--создаю таблицу shipping_info
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
	
--создаю таблицу shipping_status
drop table if exists public.shipping_status;
create table public.shipping_status (
	shippingid bigint primary key, 
	status varchar(20), 
	state varchar(20), 
	shipping_start_fact_datetime timestamp, 
	shipping_end_fact_datetime timestamp
	);