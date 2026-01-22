namespace ERP_API.Models
{
    public class EmmaRequest
    {
        public string? MachineID { get; set; }

        public string? WorkOrder { get; set; }

        public string? PlanStartDate { get; set; }

        public string? PlanEndDate { get; set; }

        public string? Building { get; set; }

        public string? Lean { get; set; }

        public string? RY { get; set; }

        public string? Model { get; set; }

        public string? Type { get; set; }
    }

    public class EmmaWorkOrderRequest
    {
        public string? ListNo { get; set; }

        public string? MachineID { get; set; }

        public string? PlanDate { get; set; }

        public string? RY { get; set; }

        public string? Part { get; set; }

        public string? Cycle { get; set; }

        public string? UserID { get; set; }

        public string? Department { get; set;}

        public string? Factory { get; set; }
    }

    public class EmmaCompleteRequest
    {
        public string? MachineID { get; set; }

        public string? StartTime { get; set; }

        public string? EndTime { get; set; }

        public List<CompleteWorkOrder>? Completed { get; set; }
    }

    public class CompleteWorkOrder
    {
        public string? WorkOrder { get; set; }

        public List<CompleteData>? Data { get; set; }
    }

    public class CompleteData
    {
        public string? RY { get; set; }

        public string? PartID { get; set; }

        public string? PartName { get; set; }

        public string? Size { get; set; }

        public int Qty { get; set;}

        public string? MaterialID { get; set; }
    }

    public class EmmaResponse
    {
        public bool Success { get; set; }

        public List<EmmaResult>? Data { get; set; }
    }

    public class EmmaResult
    {
        public string? MachineID { get; set; }

        public string? WorkOrder { get; set; }

        public string? PlanDate { get; set; }

        public string? RY { get; set; }

        public string? Model { get; set; }

        public string? PartID { get; set; }

        public string? PartName { get; set; }

        public string? Size { get; set; }

        public int Qty { get; set; }

        public string? MaterialID { get; set; }
    }

    public class EmmaFeedbackResponse
    {
        public bool Success { get; set; }
    }

    public class EmmaWorkOrderResult
    {
        public string? ListNo { get; set; }

        public string? Machine { get; set;}

        public string? PlanDate { get; set; }

        public string? DieCut { get; set; }

        public string? SKU { get; set; }

        public string? RY { get; set; }

        public string? Buy { get; set; }

        public string? ZH { get; set; }

        public string? EN { get; set; }

        public string? VI { get; set; }

        public string? Cycles { get; set; }

        public int Pairs { get; set; }

        public string? GAC { get; set; }

        public string? Status { get; set; }
    }

    public class EmmaWorkOrderInfoResult
    {
        public string? ListNo { get; set; }

        public string? Machine { get; set; }

        public string? PlanDate { get; set; }

        public string? RY { get; set; }

        public string? ZH { get; set; }

        public string? EN { get; set; }

        public string? VI { get; set; }

        public string? Cycle { get; set; }

        public int ScanQty { get; set; }
    }
}
