/* MySQL SQL Script */

DROP TABLE if EXISTS audit_message_payload;
DROP TABLE if EXISTS audit_log_points;
DROP TABLE if EXISTS audit_log_sign;
DROP TABLE if EXISTS transaction_data;
DROP TABLE IF EXISTS metrics_alerts;
DROP TABLE IF EXISTS metrics_data;
DROP TABLE IF EXISTS metric_groups;
DROP TABLE IF EXISTS processes;
DROP TABLE IF EXISTS process_groups;
DROP TABLE IF EXISTS metric_group_types_map;
DROP TABLE if EXISTS metric_group_types;
DROP TABLE if EXISTS metric_types;
DROP TABLE if EXISTS time_window_types;
DROP TABLE if EXISTS versions;

CREATE TABLE process_groups (
  ID int NOT NULL auto_increment,
  TopologyID nvarchar(32) NOT NULL,    
  Name nvarchar(255) NOT NULL,
  PRIMARY KEY (ID),
  CONSTRAINT UQ_ProcessGroups_TopologyID UNIQUE(TopologyID)  
);

CREATE TABLE processes (
  ID int NOT NULL auto_increment,
  TopologyID nvarchar(32) NOT NULL,  
  Name nvarchar(255) NOT NULL,
  Host varchar(255) NOT NULL,
  GroupID int NOT NULL,
  PRIMARY KEY (ID),
  CONSTRAINT UQ_Processes_TopologyID UNIQUE(TopologyID),
  CONSTRAINT FK_ProcessGroups_Processes_ID FOREIGN KEY(GroupID) REFERENCES process_groups(ID)
);

CREATE TABLE metric_group_types (
  ID int NOT NULL AUTO_INCREMENT,
  Name nvarchar(255) NOT NULL,
  
  PRIMARY KEY (ID),
  CONSTRAINT UQ_MetricGroupTypes_Name UNIQUE(Name)
);

CREATE TABLE metric_types (
  ID int NOT NULL AUTO_INCREMENT,
  Name nvarchar(255) NOT NULL,
  AggregationFunction enum('Unknown', 'None', 'SUM', 'AVG', 'MAX', 'MIN') NOT NULL, 

  PRIMARY KEY (ID),
  KEY `AggregationFunction` (`AggregationFunction`),                -- D-82336 
  CONSTRAINT UQ_MetricTypes_Name UNIQUE(Name)
);

CREATE TABLE metric_group_types_map (
  MetricGroupTypeID int NOT NULL,
  MetricTypeID int NOT NULL,
  CONSTRAINT PK_MetricGroupTypesMap PRIMARY KEY (MetricGroupTypeID, MetricTypeID),
  CONSTRAINT FK_MetricGroupTypesMap_MetricTypes_ID FOREIGN KEY(MetricTypeID) REFERENCES metric_types(ID),
  CONSTRAINT FK_MetricGroupTypesMap_MetricGroupTypes_ID FOREIGN KEY(MetricGroupTypeID) REFERENCES metric_group_types(ID)
);

CREATE TABLE time_window_types (
  ID int NOT NULL,
  Name nvarchar(255) NOT NULL,
  WindowSizeMillis int NOT NULL,
  PRIMARY KEY (ID)
);

# Add the currently supported entries
INSERT INTO time_window_types (ID, Name, WindowSizeMillis) VALUES(0, '5-second', 5000);
INSERT INTO time_window_types (ID, Name, WindowSizeMillis) VALUES(1, '5-minute', 300000);
INSERT INTO time_window_types (ID, Name, WindowSizeMillis) VALUES(2, '1-hour', 3600000);

CREATE TABLE metric_groups (
  ID int NOT NULL auto_increment,
  ProcessID int NOT NULL,
  MetricGroupTypeID int NOT NULL,
  Name nvarchar(255) default NULL,
  DisplayName nvarchar(255) default NULL,
  ParentID int NOT NULL,
  
  PRIMARY KEY (ID),
  KEY `Name` (`Name`),                -- D-82336 
  KEY `DisplayName` (`DisplayName`),  -- D-82336 
  KEY `ParentID` (`ParentID`),        -- D-82336 
  CONSTRAINT FK_MetricGroups_Processes_ID FOREIGN KEY(ProcessID) REFERENCES processes(ID),
  CONSTRAINT FK_MetricGroups_MetricGroupTypes_ID FOREIGN KEY(MetricGroupTypeID) REFERENCES metric_group_types(ID)
  /* do not enable constraints ParentID */
);



-- D-82336 change primary key so that MetricTimestamp is last in the composite index: "The order of the fields in the index is very important. 
-- The way b-tree works, it is more beneficial to have a field which will be used for “equality” comparison first and the 
-- fields with “range” (more than and less than comparison) second.

CREATE TABLE metrics_data (
  MetricTimestamp datetime NOT NULL,
  MetricGroupID int NOT NULL,
  MetricTypeID int NOT NULL,    
  TimeWindowTypeID int NOT NULL,
  Value BIGINT NOT NULL,
    PRIMARY KEY (MetricGroupID, MetricTypeID, TimeWindowTypeID, MetricTimestamp),  -- D-82336
    KEY `MetricTimestamp` (`MetricTimestamp`),                -- D-82336 
    CONSTRAINT FK_MetricsData_MetricGroups_ID FOREIGN KEY(MetricGroupID) REFERENCES metric_groups(ID),
    CONSTRAINT FK_MetricsData_MetricTypes_ID FOREIGN KEY(MetricTypeID) REFERENCES metric_types(ID),
    CONSTRAINT FK_MetricsData_TimeWindowTypes_ID FOREIGN KEY(TimeWindowTypeID) REFERENCES time_window_types(ID)
);


CREATE TABLE metrics_alerts (
  ID varchar(255) NOT NULL,
  ProcessID int NOT NULL,
  AlertTimestamp datetime NULL,
  AlertLevel varchar(5) NOT NULL,
  AlertType enum(
      'AlertMessage',
      'SlaBreachAlertMessage',
      'SlaClearAlertMessage') NOT NULL,
  Message nvarchar(4096) default NULL,
  MessageID varchar(255) default NULL,

  PRIMARY KEY (ID, ProcessID),
  KEY MessageID (MessageID),
  CONSTRAINT FK_MetricsAlerts_Processes_ID FOREIGN KEY(ProcessID) REFERENCES processes(ID)
);

CREATE TABLE audit_log_points (                        
     ID int NOT NULL auto_increment,     
     ProcessID int NOT NULL,
     MessageID varchar(255) NOT NULL,                
     Text longtext NOT NULL,                
     LogLevel bigint NOT NULL default '0',           
     LogTimestamp timestamp NOT NULL,
     LogTimeMillis bigint NOT NULL default '0',
     FilterName nvarchar(255) NOT NULL,               
     FilterType varchar(255) NOT NULL,
     FilterCategory varchar(255) default NULL,                                                                                         

     PRIMARY KEY  (ID),                            
     KEY MessageID (MessageID),
     CONSTRAINT FK_AuditLogPoints_Processes_ID FOREIGN KEY(ProcessID) REFERENCES processes(ID)                                             
   );

CREATE TABLE audit_message_payload (                                                                                                                         
  AuditLogPointsID int NOT NULL default '0',                                                                                                           
  MessageBody longblob default NULL,                                                                                                                                       
  MessageHeader longblob default NULL,                                                                                                                                     
  HttpRequestVerb varchar(10) default NULL,                                                                                                                    
  HttpRequestURI varchar(255) default NULL,                                                                                                                   
  HttpRequestVersion varchar(4) default NULL,                                           
  PRIMARY KEY  (AuditLogPointsID),                                                                                                                             
  CONSTRAINT FK_AuditMessagePayload_AuditLogPoints FOREIGN KEY (AuditLogPointsID) REFERENCES audit_log_points (ID) ON DELETE CASCADE ON UPDATE CASCADE  
);

CREATE TABLE audit_log_sign (      
   ProcessID int NOT NULL,                                                   
   MessageID varchar(255) NOT NULL,
   Signature longblob default NULL,                                                                  
   PRIMARY KEY  (ProcessID, MessageID),
   CONSTRAINT FK_AuditLogSign_Processes_ID FOREIGN KEY(ProcessID) REFERENCES processes(ID)                                                                                                            
 );

CREATE TABLE transaction_data (
  ProcessID int NOT NULL,
  MessageID varchar(255) NOT NULL,
  TransactionTimestamp datetime NOT NULL,
  AttributeName varchar(255) NOT NULL,
  AttributeValue nvarchar(255) NOT NULL, 
  PRIMARY KEY(ProcessID, MessageID, AttributeName),
  CONSTRAINT FK_TransactionData_Processes_ID FOREIGN KEY(ProcessID) REFERENCES processes(ID) 
);

CREATE TABLE versions (
    Name nvarchar(255) NOT NULL,
    Value nvarchar(255) NOT NULL,
    CONSTRAINT UQ_Versions_Name UNIQUE(Name)  
);

INSERT INTO versions(Name, Value) VALUES('schema', '002-leaf');

COMMIT;                 
