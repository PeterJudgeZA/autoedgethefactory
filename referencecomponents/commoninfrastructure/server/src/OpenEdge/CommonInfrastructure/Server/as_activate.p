/** -----------------------------------------------------------------------
    File        : OpenEdge/CommonInfrastructure/Server/as_activate.p
    Purpose     : 

    Syntax      :

    Description : AppServer Activation routine

    @author     : pjudge 
    Created     : Fri Jun 04 16:21:40 EDT 2010
    Notes       :
  --------------------------------------------------------------------- */
routine-level on error undo, throw.

/* ***************************  Main Block  *************************** */

/* This starts the request object and sets its ID */
OpenEdge.Lang.AgentRequest:Instance.

/* eof */