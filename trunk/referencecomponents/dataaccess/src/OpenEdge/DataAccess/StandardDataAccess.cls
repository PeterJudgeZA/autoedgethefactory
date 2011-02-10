/** ------------------------------------------------------------------------
    File        : StandardDataAccess
    Purpose     : Standard DataAccess object for filling ProDataSet-based business components.
    Syntax      : 
    Description : 
    Author(s)   : pjudge
    Created     : Tue Aug 24 15:04:40 EDT 2010
    Notes       : 
  --------------------------------------------------------------------- */
{routinelevel.i}

using OpenEdge.DataAccess.IDataAccess.
using OpenEdge.DataSource.IDataSource.
using OpenEdge.DataSource.DataSource.

using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IServiceRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IServiceResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IServiceMessage.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IFetchResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.IFetchRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.FetchResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ISaveRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ISaveResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.SaveResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ITableRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.TableRequest.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ITableResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.TableResponse.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ITableContext.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.ServiceMessageActionEnum.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.DataFormatEnum.
using OpenEdge.CommonInfrastructure.Common.ServiceMessage.TableRequestTypeEnum.

using OpenEdge.Core.System.IQueryDefinition.
using OpenEdge.Core.System.QueryDefinition.
using OpenEdge.Core.System.InvalidValueSpecifiedError.

using OpenEdge.Lang.Collections.ICollection.
using OpenEdge.Lang.Collections.IIterator.
using OpenEdge.Lang.Collections.TypedCollection.
using OpenEdge.Lang.Collections.IMap.
using OpenEdge.Lang.Collections.TypedMap.
using OpenEdge.Lang.FillModeEnum.
using OpenEdge.Lang.DataTypeEnum.
using OpenEdge.Lang.JoinEnum.
using OpenEdge.Lang.OperatorEnum.
using OpenEdge.Lang.String.


using Progress.Lang.Object.
using Progress.Lang.Class.

class OpenEdge.DataAccess.StandardDataAccess use-widget-pool abstract
        implements IDataAccess:
    
    define protected property DatasetHandle as handle no-undo get. set.
    
    define protected property FetchAllTables as logical no-undo get. set.
    
    /** A map of the IDataSource objects that this DataAccess objects knows about. */
    define public property DataSources as IMap no-undo get. private set.
    
    /* The datasources currently in use for the current request */
    
    /* [futures] This data access object could be servicing multiple concurrent requests. The 
       moCurrent* variables could (should?) be made into maps so that we can find the relevant
       objects. */
    define private variable moCurrentRequest as IServiceRequest no-undo.
    define private variable moCurrentRequestDataSources as ICollection no-undo.
    
    constructor public StandardDataAccess():
        this-object(new TypedMap(String:Type, DataSource:IDataSourceType)).
    end constructor.
    
    constructor public StandardDataAccess(input poDataSources as IMap):
        super().
        
        assign DataSources = poDataSources
               moCurrentRequestDataSources = new TypedCollection(DataSource:IDataSourceType).
    end constructor.
    
    /** Helper method for adding DataSource objects from InjectABL. It's also perfectly legitimate to
        add/remove these in the DataSources property directly.
        
        @param character The name of the datasource
        @param IDataSource The datasource object.   */
    method public void AddDataSource(input pcName as character, input poDataSource as IDataSource).
        DataSources:Put(new String(pcName), poDataSource).
    end method.

    /** Response complement method for FetchData above.
        
        @param character The message id for the request/response
        @return IFetchResponse */
    method public IFetchResponse GetData(input pcMessageId as longchar):
        define variable oIterator as IIterator no-undo.
        define variable oFetchResponse as IFetchResponse no-undo.
        define variable oTableResponse as ITableResponse no-undo.
        
        if cast(moCurrentRequest, IServiceMessage):MessageId ne pcMessageId then
            undo, throw new InvalidValueSpecifiedError('message id', ' for GetData() request').
        
        oFetchResponse = new FetchResponse(cast(moCurrentRequest, IFetchRequest)). 
        cast(oFetchResponse, IServiceMessage):SetMessageData(DatasetHandle, DataFormatEnum:ProDataSet).
        
        oIterator = moCurrentRequestDataSources:Iterator().
        do while oIterator:HasNext():
            oTableResponse = cast(oIterator:Next(), IDataSource):GetData().
            
            /* Create an entry for the request buffer. We do this here since this is the
               only place that we know that we're making a request for a particular table/buffer. */
            oFetchResponse:TableResponses:Put(oTableResponse:TableName, oTableResponse).
            
            /* cascade error flag up. */
            if oTableResponse:HasError then
                cast(oFetchResponse, IServiceResponse):HasError = true.
        end.
        
        return oFetchResponse.
        finally:
            moCurrentRequestDataSources:Clear().
            moCurrentRequest = ?.
        end finally.
    end method.
    
    method public ISaveResponse SaveData(input poRequest as ISaveRequest):
        define variable iLoop as integer no-undo.
        define variable iMax as integer no-undo.
        define variable hBuffer as handle no-undo.
        define variable oDataSource as IDataSource no-undo.
        define variable oTableResponse as ITableResponse no-undo.
        define variable oSaveResponse as ISaveResponse no-undo.
        
        moCurrentRequest = cast(poRequest, IServiceRequest).
        oSaveResponse = new SaveResponse(poRequest).
        cast(poRequest, IServiceMessage):GetMessageData(output DatasetHandle).
        
        AddDatasetCallbacks(DatasetHandle,
                            /* Should be Save or something similar. You'd expect. */
                            cast(poRequest, IServiceMessage):ActionType).
        
        /* only loop through the tables that actually have changed data. */
        iMax = extent(poRequest:TableNames).
        do iLoop = 1 to iMax:
            hBuffer = DatasetHandle:get-buffer-handle(poRequest:TableNames[iLoop]).
            
            oDataSource = cast(DataSources:Get(new String(ResolveTableName(hBuffer:name)))
                            , IDataSource).
            if valid-object(oDataSource) then
            do:
                AddBufferCallbacks(hBuffer, cast(poRequest, IServiceMessage):ActionType).
                
                /* Saves for all data in the data target (buffer in this case). 
                   hBuffer is the after-table. */
                oDataSource:SetDataTarget(hBuffer).
                
                oDataSource:Prepare(cast(poRequest, IServiceMessage):ActionType,
                                    CreateDefaultTableRequest(hBuffer:name),
                                    this-object).

                oTableResponse = oDataSource:SaveData().
                
                /* Add the table response to the total response */
                oSaveResponse:TableResponses:Put(new String(oTableResponse:TableName), oTableResponse).
                
                /* cascade error flag up to message from tableresponse */                
                if oTableResponse:HasError then
                    assign cast(oSaveResponse, IServiceResponse):HasError = true
                           cast(oSaveResponse, IServiceResponse):ErrorText = cast(oSaveResponse, IServiceResponse):ErrorText + '|' + oTableResponse:TableName. 
            end.
        end.        
        RemoveAllCallbacks(DatasetHandle, cast(poRequest, IServiceMessage):ActionType).
        
        if cast(oSaveResponse, IServiceResponse):HasError then
            cast(oSaveResponse, IServiceResponse):ErrorText = left-trim(cast(oSaveResponse, IServiceResponse):ErrorText, '|').
        
        /* Add the data to the message */
        cast(oSaveResponse, IServiceMessage):SetMessageData(DatasetHandle, DataFormatEnum:ProDataSet).
        
        return oSaveResponse.
        finally:
            moCurrentRequestDataSources:Clear().
            moCurrentRequest = ?.
        end finally.
    end method.
    
    method public void FetchData(input poRequest as IFetchRequest):
        define variable iLoop as integer no-undo.
        define variable iMax as integer no-undo.
        define variable hBuffer as handle no-undo.
        define variable oTableRequest as ITableRequest no-undo.
        define variable oDataSource as IDataSource no-undo.
        define variable oServiceMessage as IServiceMessage no-undo. 
        
        oServiceMessage = cast(poRequest, IServiceMessage).
        oServiceMessage:GetMessageData(output DatasetHandle).
        
        /* Keep a record of the current request, for use in constructing the response in GetData(). */
        moCurrentRequest = cast(poRequest, IServiceRequest).
        
        AddDatasetCallbacks(DatasetHandle, cast(poRequest, IServiceMessage):ActionType). 
        
        /* Clean out just to be sure.*/
        moCurrentRequestDataSources:Clear().
        
        assign iMax = DatasetHandle:num-buffers
               FetchAllTables = poRequest:TableRequests:IsEmpty().
        
        do iLoop = 1 to iMax:
            hBuffer = DatasetHandle:get-buffer-handle(iLoop).
            
            oTableRequest = poRequest:TableRequests:Get(hBuffer:name).
            if not valid-object(oTableRequest) and FetchAllTables then
                oTableRequest = CreateDefaultTableRequest(hBuffer:name).
            
            if valid-object(oTableRequest) and
               not oTableRequest:TableRequestType:Equals(TableRequestTypeEnum:None) then
            do:
                oDataSource = cast(DataSources:Get(new String(oTableRequest:TableName)), IDataSource).
                if valid-object(oDataSource) then
                do:
                    moCurrentRequestDataSources:Add(oDataSource).
                    
                    /* why append? */
                    /*oDataSource:FillMode = FillModeEnum:Append.*/
                    oDataSource:SetDataTarget(hBuffer).
                    oDataSource:Prepare(oServiceMessage:ActionType,
                                        oTableRequest,
                                        this-object).
                    AddBufferCallbacks(hBuffer, cast(poRequest, IServiceMessage):ActionType).
                end.
            end.
        end.
        
        /* Get data into this dataset */
        if moCurrentRequestDataSources:Size gt 0 then
        do:
            PerformFetch().
            RemoveAllCallbacks(DatasetHandle, cast(moCurrentRequest, IServiceMessage):ActionType).
        end.
    end method.
    
    /** Fetch/retrieve data from the datasource, and populate the business entity with 
        it. */
    method protected void PerformFetch():
        /* This could be a call to the individual datasources to populate their data.
            cast(moCurrentRequestDataSources:Get(1), IDataSource):PerformFetch(). */
        DatasetHandle:fill().
    end method.
    
    /** Removes all the callbacks on a dataset and its buffers, for a given action. 
        
        @param handle The dataset handle for which to remove the callbacks.
        @param ServiceMessageActionEnum The action being performed.     */
    method protected void RemoveAllCallbacks(input phDatasetHandle as handle,
                                             input poServiceMessageAction as ServiceMessageActionEnum):
        define variable iLoop as integer no-undo.
        define variable iMax as integer no-undo.
        
        iMax = phDatasetHandle:num-buffers.
        do iLoop = 1 to iMax:
            RemoveBufferCallbacks(phDatasetHandle:get-buffer-handle(iLoop), 
                                  poServiceMessageAction).
        end.
        
        RemoveDatasetCallbacks(phDatasetHandle, poServiceMessageAction).
    end method.
    
    /** Add ABL callbacks to a buffer handle for an action.
    
        @param handle The buffer on which to attach the callback
        @param ServiceMessageActionEnum The action being performed.
        
        @return Logical value indicating whether there are any callbacks set for the buffer */
    method protected logical AddBufferCallbacks(input phBuffer as handle,
                                                input poServiceMessageAction as ServiceMessageActionEnum):
            /* Example below */
            case poServiceMessageAction:
                when ServiceMessageActionEnum:FetchData then
                do:
                    /* GetDataSource(phBuffer:name):BeforeRowFill:Subscribe(XXX).*/
/*                     ohBuffer:set-callback(CallbackNameEnum:BeforeRowFill:ToString(), 'XXX', this-object).*/
                end.
                when ServiceMessageActionEnum:SaveData then
                do:
                    /*  
                    OpenEdge.DataSource.DataSource:SubscribeDataSourceEvents(
                        cast(DataSources:Get(phBuffer:name), IDataSource,
                        this-object).
                    */
                end.
            end case.
    end method.

    /** Remove ABL callbacks from a buffer handle for an action.
    
        @param handle The dataset from which to remove the callback
        @param ServiceMessageActionEnum The action being performed. */
    method protected void RemoveBufferCallbacks(input phBuffer as handle,
                                                input poServiceMessageAction as ServiceMessageActionEnum):
    end method.
    
    /** Add ABL callbacks to a buffer handle for an action.
    
        @param handle The dataset on which to attach the callback
        @param ServiceMessageActionEnum The action being performed.
        
        @return Logical value indicating whether there are any callbacks set for the buffer */
    method protected void AddDatasetCallbacks(input phDataset as handle,
                                              input poServiceMessageAction as ServiceMessageActionEnum):
        /* DatasetHandle:set-callback(CallbackNameEnum:AfterFill:ToString(), 'someThinG', this-object). */
    end method.
    
    /** Remove ABL callbacks from a dataset handle for an action.
    
        @param handle The dataset from which to remove the callback
        @param ServiceMessageActionEnum The action being performed. */            
    method protected void RemoveDatasetCallbacks(input phDataset as handle,
                                                 input poServiceMessageAction as ServiceMessageActionEnum):
    end method.
    
    /** Resolves a table name from the Business Entity into a physical table name in the
        DataSource. The values passed in here are usually taken from the ITableRequest that's
        part of the IServiceRequest.
        
        This method is typically called from a DataSource.
        
        @param character A table name in the business entity
        @return character The table name in the datasource. */
    method public character ResolveTableName (input pcBETable as character):
        return pcBETable.
    end method.
    
    /** Resolves a field name from the Business Entity into a physical field name in the
        DataSource. The values passed in here are usually taken from the ITableRequest that's
        part of the IServiceRequest.
        
        This method is typically called from a DataSource.
        
        @param character A table name in the business entity
        @param character A field name in the business entity
        @return character The field name in the datasource. */
    method public character ResolveFieldName (input pcBETable as character, input pcBEField as character):
        return pcBEField.
    end method.
    
    method protected ITableRequest CreateDefaultTableRequest(input pcBufferName as character):
        return new TableRequest(pcBufferName).
    end method.
    
end class.