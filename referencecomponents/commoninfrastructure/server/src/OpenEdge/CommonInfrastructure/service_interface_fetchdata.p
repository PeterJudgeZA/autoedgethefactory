/** ------------------------------------------------------------------------
    File        : OpenEdge/CommonInfrastructure/service_interface_fetchdata.p
    Purpose     :  
    
    Syntax      :
        
    Description : Standard Service Interface procedure for the fetchdata method
    
    @author pjudge
    Created     : Tue Jan 27 16:17:52 EST 2009
    Notes       : * The vast bulk of this code is infrastructure - the only 'real'
                    work that this procedure does is the call to ExecuteRequest().
                    The session validation should happen in the activation procedure (will as of 11.0.0);
                    the serialisation is also simply infrastructure.
                  * There are 3 separate loops that could be combined into 1 or 2 for performance reasons.
                    They remain separate here for illustrative purposes.
  ---------------------------------------------------------------------- */
{routinelevel.i}

using OpenEdge.CommonInfrastructure.ServiceMessage.IFetchRequest.
using OpenEdge.CommonInfrastructure.ServiceMessage.IFetchResponse.
using OpenEdge.CommonInfrastructure.ServiceMessage.IServiceRequest.
using OpenEdge.CommonInfrastructure.ServiceMessage.IServiceResponse.
using OpenEdge.CommonInfrastructure.ServiceMessage.IServiceMessage.

using OpenEdge.CommonInfrastructure.ServiceMessage.ServiceMessageActionEnum. 
using OpenEdge.CommonInfrastructure.IServiceMessageManager.
using OpenEdge.CommonInfrastructure.CommonServiceMessageManager.
using OpenEdge.CommonInfrastructure.ISecurityManager.
using OpenEdge.CommonInfrastructure.CommonSecurityManager.
using OpenEdge.CommonInfrastructure.IServiceManager.
using OpenEdge.CommonInfrastructure.CommonServiceManager.
using OpenEdge.CommonInfrastructure.IUserContext.

using OpenEdge.Core.Util.IObjectOutput.
using OpenEdge.Core.Util.ObjectOutputStream.
using OpenEdge.Core.Util.IObjectInput.
using OpenEdge.Core.Util.ObjectInputStream.
using OpenEdge.Core.System.ApplicationError.

using OpenEdge.Lang.ByteOrderEnum.
using OpenEdge.Lang.ABLSession.
using Progress.Lang.AppError.
using Progress.Lang.Error.
using Progress.Lang.Class.

/* ***************************  Main Block  *************************** */
define input        parameter pmRequest as memptr extent no-undo.
define output       parameter phResponseDataset as handle extent no-undo.
define output       parameter pmResponse as memptr extent no-undo.
define input-output parameter pmUserContext as memptr no-undo.

/** **/
define variable oServiceMgr as IServiceManager no-undo.
define variable oServiceMessageManager as IServiceMessageManager no-undo.
define variable oSecMgr as ISecurityManager no-undo.
define variable iLoop as integer no-undo.
define variable iMax as integer no-undo.
define variable mTemp as memptr no-undo.
define variable oOutput as IObjectOutput no-undo.
define variable oInput as IObjectInput no-undo.
define variable oRequest as IFetchRequest extent no-undo.
define variable oResponse as IServiceResponse extent no-undo.
define variable oContext as IUserContext no-undo.
define variable hDataSet as handle no-undo.

/* Deserialize requests, context */
assign iMax = extent(pmRequest)
       extent(oRequest) = iMax.

do iLoop = 1 to iMax:
    oInput = new ObjectInputStream().
    
    set-byte-order(pmRequest[iLoop]) = ByteOrderEnum:BigEndian:Value. 
     
    copy-lob pmRequest[iLoop] to file session:temp-dir + '/fetchrequest.ser'.
    
    def var i as int.
def var i2 as int.
output to value(session:temp-dir + '/fetchrequest.ser').
do i = 1 to get-size(pmRequest[iLoop]):
    i2 = get-byte(pmRequest[iLoop], i).
     
    put unformatted 
        i '~t'
        i2 '~t'         
        chr(i2) skip.
end. 
    output close.

    oInput:Read(pmRequest[iLoop]).
    oRequest[iLoop] = cast(oInput:ReadObject(), IFetchRequest).
end.

set-byte-order(pmUserContext) = ByteOrderEnum:BigEndian:Value.

oInput = new ObjectInputStream().
oInput:Read(pmUserContext).
oContext = cast(oInput:ReadObject(), IUserContext).

oServiceMgr = cast(ABLSession:Instance:SessionProperties:Get(CommonServiceManager:ServiceManagerType), IServiceManager).

/* Are we who we say we are? Note that this should really happen on activate. activate doesn't run for state-free AppServers */
oSecMgr = cast(oServiceMgr:StartService(CommonSecurityManager:SecurityManagerType)
               ,ISecurityManager).

oSecMgr:ValidateSession(oContext).


    
    def var okeys as Progress.Lang.Object extent.
    def var ovals as Progress.Lang.Object extent.

okeys = oSecMgr:CurrentUserContext:TenantId:KeySet:ToArray().
ovals = oSecMgr:CurrentUserContext:TenantId:Values:ToArray().

message '>>>>>>> oSecMgr:CurrentUserContext:UserName' oSecMgr:CurrentUserContext:UserName. 
message '>>>>>>> okeys[1]' okeys[1]. 
message '>>>>>>> ovals[1]' ovals[1]. 

oServiceMessageManager = cast(oServiceMgr:StartService(CommonServiceMessageManager:ServiceMessageManagerType)
                        , IServiceMessageManager).

/* Perform request. This is where the actual work happens.
   If this was a specialised service interface, we might construct the service request here, rather than
   taking it as an input. */
oResponse = oServiceMessageManager:ExecuteRequest(cast(oRequest, IServiceRequest)).                         

/* Serialize requests, context */
assign iMax = extent(oResponse)
       extent(pmResponse) = iMax
       extent(phResponseDataset) = iMax.

do iLoop = 1 to iMax:
    cast(oResponse[iLoop], IServiceMessage):GetMessageData(output hDataSet). 
    
    phResponseDataset[iLoop] = hDataSet. 
    
    oOutput = new ObjectOutputStream().
    oOutput:WriteObject(oResponse[iLoop]).
    oOutput:Write(output mTemp).
    pmResponse[iLoop] = mTemp.
    /* no leaks! */
    set-size(mTemp) = 0.
end.

oOutput = new ObjectOutputStream().
oOutput:WriteObject(oContext).
oOutput:Write(output pmUserContext).

error-status:error = no.
return.

/** -- error handling -- **/
catch oApplError as ApplicationError:
    return error oApplError:ResolvedMessageText().
end catch.

catch oAppError as AppError:
    return error oAppError:ReturnValue. 
end catch.

catch oError as Error:
    return error oError:GetMessage(1).
end catch.

finally:
    do iLoop = 1 to iMax:
        set-size(pmResponse[iLoop]) = 0.
    end.
    set-size(pmUserContext) = 0.
end finally.
/** -- eof -- **/