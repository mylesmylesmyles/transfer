<!--- Document Information -----------------------------------------------------

Title:      SQLValue.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Responsible for translating Query result columns values into their appropriate null/not null values

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		04/04/2008		Created

------------------------------------------------------------------------------->

<cfcomponent displayname="SQL Value" hint="Responsible for translating Query result columns values into their appropriate null/not null values" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SQLValue" output="false">
	<cfargument name="datasource" hint="The datasource BO" type="transfer.com.sql.Datasource" required="Yes" _autocreate="false">
	<cfargument name="nullable" hint="The nullable class" type="transfer.com.sql.Nullable" required="Yes" _autocreate="false">
	<cfscript>
		instance = StructNew();

		setTypes(createObject("java", "java.sql.Types"));
		setDataSource(arguments.datasource);
		setNullable(arguments.nullable);

		setLS(createObject("java", "java.lang.System").getProperty("line.separator"));

		// handle both ACF/BlueDragon and Railo 3/4 functionality
		// https://issues.jboss.org/browse/RAILO-1450
		if (server.ColdFusion.ProductName CONTAINS "Railo")
			instance.railo = true;
		else
			instance.railo = false;

		return this;
	</cfscript>
</cffunction>

<cffunction name="getPropertyColumnValue" hint="Returns the column value, but returns the default null value for the item if it is NULL" access="public" returntype="any" output="false">
	<cfargument name="query" hint="The query we are looking at" type="query" required="Yes">
	<cfargument name="object" hint="The property to get the value for" type="transfer.com.object.Object" required="Yes">
	<cfargument name="property" hint="The property to get the value for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		var value = 0;
		var type = property.getType();
		var x = 0;

		if(type eq "boolean")
		{
			//do this for booleans for postgres
			value =	arguments.query.getBoolean(arguments.property.getColumn());
		}
		else if(getDataSource().getDatabaseType() eq "oracle" AND type eq "string")
		{
			//handle oracle clobs
			if (server.coldfusion.productname eq 'Railo') {
				meta = getMetaData(arguments.query);
				for (x = 1; x <= ArrayLen(meta); x++) {
					if (meta[x].name eq arguments.property.getColumn()) {
						type = meta[x].typeName;
						break;
					}
				}
			} else {
				type = arguments.query.getMetaData().getColumnType(arguments.query.findColumn(arguments.property.getColumn()));
			}

			if(type eq getTypes().CLOB)
			{
				value =	readClob(arguments.query.getCharacterStream(arguments.property.getColumn()));
			}
			else
			{
				value =	arguments.query.getString(arguments.property.getColumn());
			}

		}
		else if(type eq "binary")
		{
			value = readBlob(arguments.query, arguments.property);
		}
		else
		{
			value =	arguments.query.getString(arguments.property.getColumn());
		}

		// railo 3/4 support per: https://groups.google.com/d/msg/transfer-dev/xkAux83LIg0/XxL57mriI34J
		if (NOT instance.railo AND arguments.query.wasNull())
		{
			return getNullable().getNullValue(arguments.object.getClassName(), arguments.property.getName());
		}
		else if (instance.railo AND NOT isDefined("value"))
		{
			value = false;
		}

		return value;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="readClob" hint="reads clob data" access="private" returntype="string" output="false">
	<!--- not required, as may return null, which will otherwise fail --->
	<cfargument name="charStream" hint="the java.io.Readear from a clob" type="any" required="No">
	<cfscript>
		var local = StructNew();
		var bufferedReader = 0;
		var stringBuffer = createObject("java", "java.lang.StringBuffer").init();

		if(NOT StructKeyExists(arguments, "charStream"))
		{
			return 0;
		}

		bufferedReader = createObject("java", "java.io.BufferedReader").init(arguments.charStream);

		local.line = bufferedReader.readLine();

		while(StructKeyExists(local, "line"))
		{
			stringBuffer.append(local.line);

			local.line = bufferedReader.readLine();

			//if there is another line, add a line break
			if((StructKeyExists(local, "line")))
			{
				stringBuffer.append(getLS());
			}
		}

		bufferedReader.close();

		return stringBuffer.toString();
	</cfscript>
</cffunction>

<cffunction name="readBlob" hint="read in a blob" access="public" returntype="any" output="false">
	<cfargument name="query" hint="The query we are looking at" type="query" required="Yes">
	<cfargument name="property" hint="The property to get the value for" type="transfer.com.object.Property" required="Yes">
	<cfscript>
		var local = StructNew();
		var column = arguments.property.getColumn();

		local.stream = arguments.query.getBinaryStream(column);

		/*
		get bytes throws a nullpointer due to some bad code, have to
		use the stream instead
		*/
		if(StructKeyExists(local, "stream"))
		{
			return arguments.query.getBytes(column);
		}

		return 0;
	</cfscript>
</cffunction>

<cffunction name="getNullable" access="private" returntype="Nullable" output="false">
	<cfreturn instance.Nullable />
</cffunction>

<cffunction name="setNullable" access="private" returntype="void" output="false">
	<cfargument name="Nullable" type="Nullable" required="true">
	<cfset instance.Nullable = arguments.Nullable />
</cffunction>

<cffunction name="getDatasource" access="private" returntype="Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

<cffunction name="getTypes" hint="java.sql.Types" access="private" returntype="any" output="false">
	<cfreturn instance.Types />
</cffunction>

<cffunction name="setTypes" access="private" returntype="void" output="false">
	<cfargument name="Types" type="any" required="true">
	<cfset instance.Types = arguments.Types />
</cffunction>

<cffunction name="getLS" access="private" returntype="string" output="false">
	<cfreturn instance.LS />
</cffunction>

<cffunction name="setLS" access="private" returntype="void" output="false">
	<cfargument name="LS" type="string" required="true">
	<cfset instance.LS = arguments.LS />
</cffunction>

</cfcomponent>