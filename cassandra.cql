CREATE KEYSPACE domain 
  WITH REPLICATION = { 
   'class' : 'SimpleStrategy', 
   'replication_factor' : 1 
  };


CREATE TABLE domain.aggregates (
    event_id uuid,
    aggregate_name text,
    domain_name text,
    version bigint,
    event_time timestamp,
    event_type text,
    correlation_id uuid,
    causation_id uuid,
    payload map<text, text>,
    PRIMARY KEY ((event_id, domain_name, aggregate_name), version)
) WITH CLUSTERING ORDER BY (version DESC);

INSERT INTO mytable JSON '{ "\"myKey\"": 0, "value": 0}' -> this from the http endpoint;

 INSERT INTO domain.aggregates (     event_id,     aggregate_name,     domain_name,     version,     event_time,     event_type,     correlation_id,     causation_id,     payload ) VALUES (     123e4567-e89b-12d3-a456-426614174000,     'TestAggregate',     'TestDomain',     1,     '2023-06-27 12:00:00',     'TestEvent',     123e4567-e89b-12d3-a456-426614174000,     123e4567-e89b-12d3-a456-426614174000,     {'key1': 'value1', 'key2': 'value3'} );

INSERT INTO domain.aggregates (event_id, aggregate_name, domain_name, version, event_time, event_type, correlation_id, causation_id, payload ) VALUES (123e4567-e89b-12d3-a456-426614174000, 'TestAggregate', 'TestDomain', 1, '2023-06-27 12:00:00', 'TestEvent', 123e4567-e89b-12d3-a456-426614174000, 123e4567-e89b-12d3-a456-426614174000, {'key1': 'value1', 'key2': 'value3'} );
insert into domain.aggregates (uuid("dbfff36a-14ad-11ee-be56-0242ac120002"))
// take into account that map is not exactly like json, is just a list of str:str, so you can parse or in modeling make the parsing for that stuff

CREATE TABLE domain.flow (
  race_name text, 
  race_position int, 
  cyclist_name FROZEN<fullname>, 
  PRIMARY KEY (race_name, race_position));