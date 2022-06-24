--==================--==================
--==================--==================
--DWH: Пересмотр модели данных
--==================--==================
--Проект
--==================--==================
--UPDATE таблиц
--==================--==================

--пополняю таблицу shipping_country_rates
insert into public.shipping_country_rates 
	(shipping_country, shipping_country_base_rate)
		select 
			shipping_country::varchar(20), shipping_country_base_rate::numeric(14,3)
		from public.shipping s
		group by shipping_country, shipping_country_base_rate;
		
--пополняю таблицу shipping_agreement
insert into public.shipping_agreement (
	agreementid, agreement_number, agreement_rate, agreement_commission)
	select distinct 
		(regexp_split_to_array(vendor_agreement_description, '\:'))[1]::bigint as agreementid,
		(regexp_split_to_array(vendor_agreement_description, '\:'))[2]::varchar(30) as agreement_number,
		(regexp_split_to_array(vendor_agreement_description, '\:'))[3]::numeric(14,2) as agreement_rate,
		(regexp_split_to_array(vendor_agreement_description,'\:'))[4]::numeric(14,2) as agreement_commission
	from public.shipping;

--пополню таблицу shipping_transfer
insert into public.shipping_transfer(
	transfer_type, transfer_model, shipping_transfer_rate)
	select 
		(regexp_split_to_array(shipping_transfer_description,'\:'))[1]::varchar(2) as transfer_type,
		(regexp_split_to_array(shipping_transfer_description,'\:'))[2]::varchar(20) as transfer_model,
		shipping_transfer_rate::numeric(14,3)
	from public.shipping 
	group by transfer_type, transfer_model, shipping_transfer_rate;
	
--пополню таблицу shipping_info
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

--заполняю таблицу shipping_status
insert into public.shipping_status (
	shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
	with fin as (
		select 
			distinct shippingid, state_datetime, status, state
		from public.shipping s 
		where state in ('booked','recieved')),
	fin_sh as (
		select 
			distinct t.shippingid::bigint as shippingid
			, t.status::varchar as status
			, t.state::varchar as state
			, t1.state_datetime::timestamp as shipping_start_fact_datetime
			, t.state_datetime::timestamp as shipping_end_fact_datetime
		from fin t
		join fin t1 on t.shippingid = t1.shippingid
			and t1.state = 'booked'
		where t.state = 'recieved'
		)
	select shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime
	from fin_sh;