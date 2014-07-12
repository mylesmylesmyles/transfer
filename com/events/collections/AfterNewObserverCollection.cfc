<!--- Document Information -----------------------------------------------------

Title:      AfterNewObserverCollection.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Collection of observers for after new event

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		22/02/2007		Newd

------------------------------------------------------------------------------->
<cfcomponent name="AfterNewObserverCollection" hint="Collection of Observers for after a New" extends="AbstractBaseObserverCollection">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="AfterNewObserverCollection" output="false">
	<cfscript>
		super.init();

		return this;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="fireActionMethod" hint="virtual: fires the action method" access="private" returntype="void" output="false">
	<cfargument name="object" hint="the object to fire against" type="any" required="Yes">
	<cfargument name="event" hint="The event object to fire" type="transfer.com.events.TransferEvent" required="Yes">
	<cfscript>
		arguments.object.actionAfterNewTransferEvent(arguments.event);
	</cfscript>
</cffunction>

</cfcomponent>