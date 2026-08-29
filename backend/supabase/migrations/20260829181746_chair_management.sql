-- Backfill missing chairs for existing tables and allow removing a single
-- unoccupied seat from a table (capacity shrinks accordingly).

CREATE OR REPLACE FUNCTION public.ensure_chairs_for_table(p_table_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_event_id uuid;
  v_table public.seating_tables;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  v_event_id := public.current_event_id();

  SELECT * INTO v_table
  FROM public.seating_tables
  WHERE id = p_table_id AND event_id = v_event_id;
  IF v_table.id IS NULL THEN
    RAISE EXCEPTION 'Table not found';
  END IF;

  INSERT INTO public.chairs(event_id, table_id, chair_number)
  SELECT v_event_id, v_table.id, number
  FROM generate_series(1, v_table.capacity) AS number
  WHERE NOT EXISTS (
    SELECT 1 FROM public.chairs c
    WHERE c.table_id = v_table.id AND c.chair_number = number
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_chair(p_chair_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_event_id uuid;
  v_chair public.chairs;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  v_event_id := public.current_event_id();

  SELECT * INTO v_chair
  FROM public.chairs
  WHERE id = p_chair_id AND event_id = v_event_id
  FOR UPDATE;
  IF v_chair.id IS NULL THEN
    RAISE EXCEPTION 'Chair not found';
  END IF;
  IF v_chair.guest_id IS NOT NULL THEN
    RAISE EXCEPTION 'Cannot delete an occupied chair';
  END IF;

  DELETE FROM public.chairs WHERE id = p_chair_id;

  UPDATE public.seating_tables
  SET capacity = capacity - 1
  WHERE id = v_chair.table_id AND event_id = v_event_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.ensure_chairs_for_table(uuid) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_chair(uuid) TO anon, authenticated, service_role;
