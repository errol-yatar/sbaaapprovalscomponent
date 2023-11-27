import { LightningElement } from "lwc";
import retrievePendingApprovals from "@salesforce/apex/ApprovalsHomeComponentController.getPendingApprovals";
import approveReject from "@salesforce/apex/ApprovalsHomeComponentController.approveReject";
import getColumns from "./approvalsHomeTableColumns";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ApprovalsHomeComponent extends LightningElement {
    hasData = false;
    hasLoaded = false;
    hasSelections = false;

    componentHeader = "My Approvals";
    myApprovalsIcon = "utility:check";
    myTeamApprovalsIcon = "";

    columns = [];
    data = [];

    selectedApprovalIds = [];
    isRejectionModalVisible = false;
    rejectionComments = "";

    connectedCallback() {
        // this.reloadData();
        this.columns = getColumns("myApprovals");
        this.loadData("myApprovals");
    }

    handleReload() {
        /*setTimeout(() => {
            this.hasLoaded = true;
            this.hasData = !this.hasData;
        }, 1000);*/
        this.loadData("myApprovals");
    }

    handleRowSelect(event) {
        let selectedRows = event.detail.selectedRows;
        this.hasSelections = selectedRows.length > 0;

        this.selectedApprovalIds = [];
        if (this.hasSelections) {
            for (let i = 0; i < selectedRows.length; i++) {
                this.selectedApprovalIds.push(selectedRows[i].id);
            }
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case "approve":
                window.open(`/apex/sbaa__Approve?id=${row.id}`, "_blank");
                break;
            case "reject":
                window.open(`/apex/sbaa__Reject?id=${row.id}`, "_blank");
                break;
            default:
        }
    }

    showRejectionCommentsModal() {
        this.isRejectionModalVisible = true;
    }

    closeRejectionCommentsModal() {
        this.isRejectionModalVisible = false;
    }

    handleCommentChange(event) {
        this.rejectionComments = event.detail.value;
    }

    handleMassAction(event) {
        let action = event.target.label;
        this.hasLoaded = false;
        this.hasSelections = false;
        this.isRejectionModalVisible = false;
        let resultsMap = [];
        for (let approvalId of this.selectedApprovalIds) {
            resultsMap[approvalId] = false;
        }
        for (let approvalId of this.selectedApprovalIds) {
            approveReject({
                approvalId,
                doApprove: action === "Approve",
                comments: this.rejectionComments
            })
                .then((response) => {
                    let actualResponse = JSON.parse(response);
                    resultsMap[approvalId] = true;
                    const allDone = Object.values(resultsMap).every(
                        (result) => result === true
                    );
                    if (allDone) {
                        if (actualResponse.success) {
                            this.hasLoaded = true;
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: "Action Submitted",
                                    message: "",
                                    variant: "success",
                                    mode: "dismissable"
                                })
                            );
                            return this.loadData("myApprovals");
                        }
                        this.hasLoaded = true;
                        console.error(actualResponse.error);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Error",
                                message: actualResponse.error,
                                variant: "error",
                                mode: "dismissable"
                            })
                        );
                    }
                    return Promise.resolve();
                })
                .catch((error) => {
                    this.hasLoaded = true;
                    console.error(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Error!",
                            message: error,
                            variant: "error",
                            mode: "dismissable"
                        })
                    );
                });
        }
    }

    handleApprovalListSelect(event) {
        let selectedItemValue = event.detail.value;
        this.myApprovalsIcon = "";
        this.myTeamApprovalsIcon = "";
        this.componentHeader = "My Approvals";
        if (selectedItemValue === "myApprovals") {
            this.myApprovalsIcon = "utility:check";
        } else if (selectedItemValue === "myTeamApprovals") {
            this.myTeamApprovalsIcon = "utility:check";
            this.componentHeader = "My Team's Approvals";
        }
        this.columns = getColumns(selectedItemValue);
        this.loadData(selectedItemValue);
    }

    loadData(listType) {
        if (!listType) listType = "myApprovals";
        this.hasLoaded = false;
        retrievePendingApprovals({ listType })
            .then((result) => {
                this.prepareTableData(result);
            })
            .catch((error) => {
                // TODO: Add error handling here
                console.error(error);
            })
            .finally(() => {
                this.hasLoaded = true;
            });
    }

    // TODO: Move this function to a separate file
    prepareTableData(records) {
        let tableData = [];
        // Start preparing data
        for (let i = 0; i < records.length; i++) {
            let record = records[i];
            let tblDataObj = {
                id: record.Id,
                assignedTo: record.sbaa__Approver__r.Name,
                opptyUrl: `/lightning/r/Opportunity/${record.Quote__r.SBQQ__Opportunity2__c}/view`,
                opptyName: record.Quote__r.SBQQ__Opportunity2__r.Name,
                quoteOwner: record.Quote__r.Owner.Name,
                accountUrl: `/lightning/r/Account/${record.Quote__r.SBQQ__Account__c}/view`,
                accountName: record.Quote__r.SBQQ__Account__r.Name,
                quoteUrl: `/lightning/r/SBQQ__Quote__c/${record.Quote__c}/view`,
                quoteName: record.Quote__r.Name,
                discountAmt:
                    record.Quote__r.SBQQ__TotalCustomerDiscountAmount__c,
                partnerDiscount: record.Quote__r.SBQQ__PartnerDiscount__c / 100,
                distributorDiscount:
                    record.Quote__r.SBQQ__DistributorDiscount__c / 100,
                amtTotal: record.Quote__r.SBQQ__ListAmount__c,
                approveUrl: `/apex/sbaa__Approve?id=${record.Id}`,
                rejectUrl: `/apex/sbaa__Reject?id=${record.Id}`
            };
            if (record.sbaa__Rule__c && record.sbaa__Rule__r.Name) {
                tblDataObj.approvalRuleURL = `/lightning/r/sbaa__ApprovalRule__c/${record.sbaa__Rule__c}/view`;
                tblDataObj.relatedToRuleName = record.sbaa__Rule__r.Name;
            }
            tableData.push(tblDataObj);
        }
        this.hasData = tableData.length > 0;
        this.data = tableData;
    }
}
