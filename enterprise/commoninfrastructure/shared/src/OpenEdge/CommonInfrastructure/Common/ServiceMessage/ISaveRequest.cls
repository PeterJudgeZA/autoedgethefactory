/** ------------------------------------------------------------------------
    File        : ISaveRequest
    Purpose     : Interface for data save request  
    Syntax      : 
    Description : 
    @author hdaniels
    Created     : Tue Feb 09 14:28:13 EST 2010
    Notes       : 
  ---------------------------------------------------------------------- */
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IServiceRequest.

interface OpenEdge.CommonInfrastructure.Common.ServiceMessage.ISaveRequest inherits IServiceRequest:
    
    /** Indicates whether and how the records being saved need to be updated from the tables that
        have been written */
    define public property RefreshPolicy as TableRequestTypeEnum no-undo get. set.
    
    /** A list of tables being saved */
    define public property TableNames as character extent no-undo get. set.
    
    @todo(task="refactor", action="").
    /** (mandatory) A collection of one of more tables for this request. 
    define public property TableRequests as ITableRequestCollection no-undo get.
    */
    
end interface.