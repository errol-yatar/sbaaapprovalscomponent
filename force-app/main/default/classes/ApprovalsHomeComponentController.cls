/**
 * @File Name          : ApprovalsHomeComponentController.cls
 * @Description        :
 * @Author             : Errol John Yatar
 * @Group              :
 * @Last Modified By   : Errol John Yatar
 * @Last Modified On   : 29.MAR.2020, 9:34:40 PM
 * @Modification Log   :
 * Ver      Date            Author              Modification
 * 1.0      29.MAR.2020     Errol John Yatar    Initial Version
 **/
public without sharing class ApprovalsHomeComponentController {
    @TestVisible
    private static Boolean doThrowError = false;

    @AuraEnabled
    public static List<sbaa__Approval__c> getPendingApprovals(String listType) {
        List<sbaa__Approval__c> allApprovals = new List<sbaa__Approval__c>();
        if (listType == 'myApprovals') {
            List<sbaa__Approval__c> approvals = [
                SELECT
                    Id,
                    Name,
                    sbaa__Actions__c,
                    sbaa__Approver__c,
                    sbaa__Approver__r.Name,
                    sbaa__RecordField__c,
                    Quote__r.SBQQ__Account__c,
                    Quote__r.SBQQ__Account__r.Name,
                    sbaa__AssignedTo__c,
                    sbaa__AssignedToMe__c,
                    sbaa__AssignedGroupId__c,
                    CreatedById,
                    CreatedDate,
                    Quote__c,
                    Quote__r.Name,
                    Quote__r.SBQQ__Opportunity2__c,
                    Quote__r.SBQQ__Opportunity2__r.Name,
                    Quote__r.Owner.Name,
                    Quote__r.SBQQ__AverageCustomerDiscount__c,
                    Quote__r.SBQQ__TotalCustomerDiscountAmount__c,
                    Quote__r.SBQQ__PartnerDiscount__c,
                    Quote__r.SBQQ__DistributorDiscount__c,
                    Quote__r.SBQQ__ListAmount__c,
                    Quote__r.TRAC_Business_Reason__c,
                    Quote__r.Max_Line_Discount2__c,
                    Quote__r.UBB_Max_Line_Discount__c,
                    sbaa__Rule__c,
                    sbaa__Rule__r.Name,
                    sbaa__AssignedTo__r.Name
                FROM sbaa__Approval__c
                WHERE
                    (sbaa__AssignedToMe__c = TRUE
                    OR sbaa__AssignedGroupId__c != NULL)
                    AND sbaa__Status__c IN ('Requested')
                    AND sbaa__Archived__c = FALSE
                    AND Quote__c != NULL
            ];

            // For approvers assigned to a group, filter out any groups the current user isn't a member of.
            List<Id> groupIds = new List<Id>();
            for (sbaa__Approval__c approval : approvals) {
                if (listType == 'myApprovals') {
                    if (approval.sbaa__AssignedToMe__c == true) {
                        allApprovals.add(approval);
                    }
                }
                if (approval.sbaa__AssignedGroupId__c != null) {
                    groupIds.add(approval.sbaa__AssignedGroupId__c);
                }
            }

            Map<Id, Group> groups = new Map<Id, Group>(
                [
                    SELECT Id, Type, (SELECT UserOrGroupId FROM GroupMembers)
                    FROM Group
                    WHERE Id IN :groupIds
                ]
            );
            List<User> managedUsers = [
                SELECT Id
                FROM User
                WHERE ManagerId = :UserInfo.getUserId()
            ];

            for (sbaa__Approval__c groupApproval : approvals) {
                if (
                    groupApproval.sbaa__AssignedGroupId__c != null &&
                    groups.containsKey(groupApproval.sbaa__AssignedGroupId__c)
                ) {
                    Group aGroup = groups.get(
                        groupApproval.sbaa__AssignedGroupId__c
                    );
                    Set<Id> groupMemberIds = new Set<Id>();
                    for (GroupMember gm : aGroup.GroupMembers) {
                        groupMemberIds.add(gm.UserOrGroupId);
                    }
                    if (!groupMemberIds.isEmpty()) {
                        if (
                            listType == 'myApprovals' &&
                            groupMemberIds.contains(UserInfo.getUserId())
                        ) {
                            allApprovals.add(groupApproval);
                        }
                    }
                }
            }
        } else if (listType == 'myTeamApprovals') {
            Map<String, Simple_Role_Mapping__mdt> roleInfoMap = new Map<String, Simple_Role_Mapping__mdt>();
            Map<Id, User> usersInfoMap = new Map<Id, User>(
                [
                    SELECT Id, Name, Simple_Role_Name__c
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                ]
            );

            List<User> managedUsers = [
                SELECT Id, Name, Simple_Role_Name__c
                FROM User
                WHERE
                    ManagerId = :UserInfo.getUserId()
                    OR Id = :UserInfo.getUserId()
            ];

            Set<String> userRoles = new Set<String>();

            for (User u : managedUsers) {
                userRoles.add(u.Simple_Role_Name__c);
            }

            List<Simple_Role_Mapping__mdt> roleInfo = [
                SELECT
                    Id,
                    Simple_Role_Name__c,
                    UserRole_Name__c,
                    Discount_Threshold__c
                FROM Simple_Role_Mapping__mdt
                WHERE Simple_Role_Name__c IN :userRoles
            ];

            for (Simple_Role_Mapping__mdt srm : roleInfo) {
                roleInfoMap.put(srm.Simple_Role_Name__c, srm);
            }

            Set<Id> userWithMyDiscount = new Set<Id>();

            for (User u : managedUsers) {
                if (
                    roleInfoMap.get(u.Simple_Role_Name__c) != null &&
                    roleInfoMap.get(u.Simple_Role_Name__c)
                        .Discount_Threshold__c ==
                    roleInfoMap.get(
                            usersInfoMap.get(UserInfo.getUserId())
                                .Simple_Role_Name__c
                        )
                        .Discount_Threshold__c &&
                    u.Id != UserInfo.getUserId()
                ) {
                    userWithMyDiscount.add(u.Id);
                }
            }

            allApprovals = [
                SELECT
                    Id,
                    Name,
                    sbaa__Actions__c,
                    sbaa__Approver__c,
                    sbaa__Approver__r.Name,
                    sbaa__RecordField__c,
                    Quote__r.SBQQ__Account__c,
                    Quote__r.SBQQ__Account__r.Name,
                    sbaa__AssignedTo__c,
                    sbaa__AssignedToMe__c,
                    sbaa__AssignedGroupId__c,
                    CreatedById,
                    CreatedDate,
                    Quote__c,
                    Quote__r.Name,
                    Quote__r.SBQQ__Opportunity2__c,
                    Quote__r.SBQQ__Opportunity2__r.Name,
                    Quote__r.Owner.Name,
                    Quote__r.SBQQ__AverageCustomerDiscount__c,
                    Quote__r.SBQQ__TotalCustomerDiscountAmount__c,
                    Quote__r.SBQQ__PartnerDiscount__c,
                    Quote__r.SBQQ__DistributorDiscount__c,
                    Quote__r.SBQQ__ListAmount__c,
                    sbaa__Rule__c,
                    sbaa__Rule__r.Name,
                    sbaa__AssignedTo__r.Name
                FROM sbaa__Approval__c
                WHERE
                    sbaa__Status__c IN ('Requested')
                    AND sbaa__Approver__r.sbaa__User__c IN :userWithMyDiscount
                    AND sbaa__Archived__c = FALSE
                    AND Quote__c != NULL
            ];
        }
        return allApprovals;
    }

    @AuraEnabled
    public static String approveReject(
        Id approvalId,
        Boolean doApprove,
        String comments
    ) {
        Map<String, Object> responseObj = new Map<String, Object>();
        responseObj.put('success', true);

        try {
            sbaa__Approval__c approvalRec = [
                SELECT Id, sbaa__AssignedToMe__c
                FROM sbaa__Approval__c
                WHERE Id = :approvalId
            ];
            if (approvalRec.sbaa__AssignedToMe__c == false) {
                update new sbaa__Approval__c(
                    Id = approvalId,
                    sbaa__AssignedTo__c = UserInfo.getUserId()
                );
            }
            SBAA.ServiceRouter.save(
                'SBAA.ApprovalRestApiProvider.' +
                (doApprove ? 'Approve' : 'Reject'),
                '{\"approvalId\": \"' +
                    approvalId +
                    '\",\"comments\":\"' +
                    comments +
                    '\"}'
            );
        } catch (Exception ex) {
            responseObj.put('success', false);
            responseObj.put('error', ex.getMessage());
            responseObj.put('stack', ex.getStackTraceString());
        }
        return JSON.serialize(responseObj);
    }

    private class CustomException extends Exception {
    }
}