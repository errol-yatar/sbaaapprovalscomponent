const rowActions = [
    { label: "Approve", name: "approve" },
    { label: "Reject", name: "reject" }
];

export default function getColumns(listType) {
    var columns = [
        {
            label: "Quote",
            fieldName: "quoteUrl",
            type: "url",
            typeAttributes: {
                label: { fieldName: "quoteName" },
                target: "_blank"
            },
            sortable: true
        },
        {
            label: "Quote Owner",
            fieldName: "quoteOwner",
            type: "text",
            sortable: true
        },
        {
            label: "Opportunity",
            fieldName: "opptyUrl",
            type: "url",
            typeAttributes: {
                label: { fieldName: "opptyName" },
                target: "_blank"
            },
            sortable: true,
            wrapText: true
        },
        {
            label: "Discount (%)",
            fieldName: "discountPercent",
            type: "percent",
            typeAttributes: {
                minimumFractionDigits: 2
            },
            sortable: true
        },
        {
            label: "UBB Discount (%)",
            fieldName: "UBBdiscountPercent",
            type: "percent",
            typeAttributes: {
                minimumFractionDigits: 2
            },
            sortable: true
        },
        {
            label: "Amount Total",
            fieldName: "amtTotal",
            type: "currency",
            typeAttributes: {
                currencyCode: "USD"
            },
            sortable: true
        },
        {
            label: "Approval Rule",
            fieldName: "approvalRuleURL",
            type: "url",
            typeAttributes: {
                label: { fieldName: "relatedToRuleName" },
                target: "_blank"
            },
            sortable: true,
            wrapText: true
        },
        {
            label: "Business Reason",
            fieldName: "businessReason",
            type: "text",
            sortable: true,
            wrapText: true
        },
        {
            type: "action",
            typeAttributes: { rowActions: rowActions }
        }
    ];
    if (listType === "myTeamApprovals") {
        columns.unshift({
            label: "Approver",
            fieldName: "assignedTo",
            type: "text",
            sortable: true
        });
    }
    return columns;
}
