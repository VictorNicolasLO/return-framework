CREATE KEYSPACE domain 
  WITH REPLICATION = { 
   'class' : 'SimpleStrategy', 
   'replication_factor' : 1 
  };


CREATE TABLE domain.aggregates (
    domain_name text,
    aggregate_name text,
    aggregate_id uuid,
    version bigint,
    causation_id tuple<text, text, uuid, bigint>,
    event_time timestamp,
    event_type text,
    payload map<text, text>,
    PRIMARY KEY ((domain_name, aggregate_name, aggregate_id), version)
) WITH CLUSTERING ORDER BY (version ASC);



INSERT INTO mytable JSON '{ "\"myKey\"": 0, "value": 0}' -> this from the http endpoint;


INSERT INTO domain.aggregates (domain_name, aggregate_name, aggregate_id,  version, event_time, event_type, causation_id, payload ) VALUES ( 'TestDomain', 'TestAggregate', 123e4567-e89b-12d3-a456-426614174001, 1, '2023-06-27 12:00:00', 'TestEvent', ('Domain2', 'Flow2', 123e4567-e89b-12d3-a456-426614174000, 2), {'key1': 'value1', 'key2': 'value3'} );
select * from domain.aggregates where domain_name='domain_name'and aggregate_name = 'aggregate_name' and aggregate_id=123e4567-e89b-12d3-a456-426614174001 and version=5
// take into account that map is not exactly like json, is just a list of str:str, so you can parse or in modeling make the parsing for that stuff


CREATE TABLE domain.flow (
  race_name text, 
  race_position int, 
  cyclist_name FROZEN<fullname>, 
  PRIMARY KEY (race_name, race_position));