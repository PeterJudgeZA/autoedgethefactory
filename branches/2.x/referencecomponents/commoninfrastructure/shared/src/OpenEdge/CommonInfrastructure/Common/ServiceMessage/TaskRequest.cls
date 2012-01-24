/** ------------------------------------------------------------------------
    File        : TaskRequest
    Purpose     : 
    Syntax      : 
    Description : 
    @author pjudge
    Created     : Wed Jan 26 10:32:36 EST 2011
    Notes       : 
  ---------------------------------------------------------------------- */
routine-level on error undo, throw.

using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ServiceRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ServiceMessageActionEnum.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ITaskRequest.

using OpenEdge.Core.Util.IExternalizable.
using OpenEdge.Core.Util.IObjectInput.
using OpenEdge.Core.Util.IObjectOutput.
using OpenEdge.Lang.Collections.ICollection.
using OpenEdge.Lang.Collections.Collection.

class OpenEdge.CommonInfrastructure.Common.ServiceMessage.TaskRequest inherits ServiceRequest
        implements ITaskRequest, IExternalizable: 

	define public property ServiceRequests as ICollection no-undo
        get():
            if not valid-object(ServiceRequests) then
                ServiceRequests = new Collection().
            
            return ServiceRequests.
        end get.
	private set.

	constructor public TaskRequest(input pcMessageId as longchar,
	                               input pcService as character,
	                               input poActionType as ServiceMessageActionEnum ):
		super (input pcMessageId, input pcService, input poActionType).
	end constructor.

	constructor public TaskRequest(input pcService as character,
	                               input poMessageType as ServiceMessageActionEnum ):
		super (input pcService, input poMessageType).
	end constructor.
	

    method override public void ReadObject(input poStream as IObjectInput ):
        super:ReadObject(input poStream).
        
        ServiceRequests:AddArray(poStream:ReadObjectArray()).
    end method.

    method override public void WriteObject(input poStream as IObjectOutput ):
        super:WriteObject(input poStream).
        
        poStream:WriteObjectArray(ServiceRequests:ToArray()).
    end method.

	
end class.