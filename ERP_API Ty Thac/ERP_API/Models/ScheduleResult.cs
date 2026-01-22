namespace ERP_API.Models
{
    public class ScheduleLean
    {
        public string? Lean { get; set; }

        public List<int>? Holiday { get; set; }

        public List<Sequence>? Sequence { get; set; }
    }

    public class Sequence
    {
        public int Index { get; set; }

        public List<ScheduleResult>? Schedule { get; set; }
    }

    public class ScheduleResult
    {
        public string? Date { get; set; }

        public string? Order { get; set; }

        public string? SubOrder { get; set; }

        public string? SubTitle { get; set; }

        public string? DieCutMold { get; set; }

        public string? Material { get; set; }

        public string? LastMold { get; set; }

        public string? BuyNo { get; set; }

        public string? SKU { get; set; }

        public int Labor { get; set; }

        public int Pairs { get; set; }

        public string? ShipDate { get; set; }

        public string? Country { get; set; }

        public string? Location { get; set; }

        public bool? IsToday { get; set; }

        public string? MatStatus { get; set; }

        public string? FTT { get; set; }

        public string? Progress { get; set; }

        public string? Progress_S { get; set; }

        public string? Progress_A { get; set; }

        public string? Progress_W { get; set; }
    }

    public class LastDate
    {
        public string? Date { get; set; }
    }

    public class LaborDemandResult
    {
        public List<LaborData>? Cutting { get; set; }

        public List<LaborData>? Stitching { get; set; }

        public List<LaborData>? Assembly { get; set; }

        public List<LaborData>? Total { get; set; }
    }

    public class LaborData
    {
        public int? Id { get; set; }

        public string? Date { get; set; }

        public int Qty { get; set; }
    }

    public class LeanStandard
    {
        public string? Lean { get; set; }

        public List<ModelStandard>? Models { get; set; }
    }

    public class ModelStandard
    {
        public string? Model { get; set; }

        public string? DieCut { get; set; }

        public string? SKU { get; set; }

        public int Labor_C { get; set; }

        public int Labor_S { get; set; }

        public int Labor_A { get; set; }

        public int Labor_P { get; set; }

        public int Labor_Indirect { get; set; }

        public int Standard { get; set; }

        public int Target { get; set; }
    }

    public class LeanPlan
    {
        public string? Lean { get; set; }

        public List<PlanRY>? Plan { get; set; }
    }

    public class PlanRY
    {
        public string? Version { get; set; }

        public string? RY { get; set; }

        public string? ShipDate { get; set; }

        public string? Type { get; set; }

        public string? BuyNo { get; set; }

        public string? SKU { get; set; }

        public int Pairs { get; set; }

        public int CompletedPairs { get; set; }

        public string? DieCut { get; set; }

        public string? Outsole { get; set; }

        public int CyclePairs { get; set; }

        public string? Cycle { get; set; }

        public string? Last { get; set; }

        public string? TotalCycle { get; set; }

        public string? DeliveryTime { get; set; }

        public int Seq { get; set; }

        public string? AssemblyTime { get; set; }

        public string? Remark { get; set; }

        public string? Country { get; set; }

        public string? Status { get; set; }
    }

    public class ProductionScheduleLean
    {
        public string? Building { get; set; }

        public string? Lean { get; set; }

        public string? TargetEff { get; set; }

        public string? ActualEff_A { get; set; }

        public string? ActualEff_S { get; set; }

        public string? HisEff_A { get; set; }

        public string? HisEff_S { get; set; }

        public string? HisPPH_A { get; set; }

        public string? HisPPH_S { get; set; }

        public List<ProductionSchedule>? Schedule { get; set; }

        public List<WorkDay>? WorkDays { get; set; }
    }

    public class ProductionSchedule
    {
        public string? StartDate { get; set; }

        public string? EndDate { get; set; }

        public int Value { get; set; }

        public string? BUY { get; set; }

        public string? Type { get; set; }

        public string? RY { get; set; }

        public int Pairs { get; set; }

        public string? GAC { get; set; }

        public string? CuttingDie { get; set; }

        public string? SKU { get; set; }

        public string? ModelCategory { get; set; }

        public string? StitchingCode { get; set; }

        public int IE_LaborS { get; set; }

        public string? LSCategory { get; set; }

        public string? AssemblyCode { get; set; }

        public int IE_LaborA { get; set; }

        public string? LACategory { get; set; }

        public int DaysBeforeGAC { get; set; }

        public string? GACCategory { get; set; }

        public int PM_Capacity { get; set; }

        public int IE_Capacity { get; set; }

        public string? C_Eff_RY_A { get; set; }

        public string? Eff_RY_A { get; set; }

        public string? C_Eff_RY_S { get; set; }

        public string? Eff_RY_S { get; set; }

        public string? C_TargetEff { get; set; }

        public string? TargetEff { get; set; }

        public string? C_HisEff_A { get; set; }

        public string? HisEff_A { get; set; }

        public string? C_HisPPH_A { get; set; }

        public string? HisPPH_A { get; set; }

        public string? TargetPPH_A { get; set; }

        public string? PPHRate_A { get; set; }

        public string? C_HisEff_S { get; set; }

        public string? HisEff_S { get; set; }

        public string? C_HisPPH_S { get; set; }

        public string? HisPPH_S { get; set; }

        public string? TargetPPH_S { get; set; }

        public string? PPHRate_S { get; set; }

        public string? Lean_S { get; set; }
    }

    public class WorkDay
    {
        public string? StartDate { get; set; }

        public string? EndDate { get; set; }

        public string? WorkHour { get; set; }
    }

    public class ScheduleVersion
    {
        public string? Version { get; set; }

        public string? OrderDate { get; set; }
    }

    public class CycleDispatchList
    {
        public string? ListNo { get; set; }

        public string? Type { get; set; }

        public int Pairs { get; set; }

        public string? Remark { get; set; }

        public string? RY { get; set; }

        public string? Time { get; set; }

        public bool Confirmed { get; set; }

        public List<string>? Cycle { get; set; }
    }

    public class LeanEstimatedInfo
    {
        public string? Building { get; set; }

        public string? Lean { get; set; }

        public string? TargetEff { get; set; }

        public string? EstEff_A { get; set; }

        public string? EstEff_S { get; set; }

        public List<ModelRisk>? Model_A { get; set; }

        public List<ModelRisk>? Model_S { get; set; }
    }

    public class ModelRisk
    {
        public string? Model { get; set; }

        public string? Type { get; set; }

        public int LaborDiff { get; set; }

        public string? HisEff { get; set; }
    }

    public class SecondProcess
    {
        public string? P_EN { get; set; }

        public string? P_CH { get; set; }

        public string? P_VN { get; set; }

        public string? C_EN { get; set; }

        public string? C_CH { get; set; }

        public string? C_VN { get; set; }

        public int Pairs { get; set; }

        public int Finished { get; set; }

        public string? LaunchDate { get; set; }

        public string? EndDate { get; set; }
    }

    public class MaterialStatus
    {
        public string? MatID { get; set; }

        public string? MatName { get; set; }

        public string? SupID { get; set; }

        public string? SupName { get; set; }

        public string? Unit { get; set; }

        public double Usage { get; set; }

        public double InStock { get; set; }

        public string? ArrivalDate { get; set; }

        public string? EstimatedDate { get; set; }
    }

    public class RYDefects
    {
        public int Seq { get; set; }

        public string? EN { get; set; }

        public string? VN { get; set; }

        public string? CH { get; set; }

        public int Pairs { get; set; }
    }

    public class BuildingCapacity
    {
        public string? Group { get; set; }

        public string? Building { get; set; }

        public List<LeanCapacity>? Lean { get; set; }
    }

    public class LeanCapacity
    {
        public string? Lean { get; set; }

        public string? Type { get; set; }

        public int T_Finished { get; set; }

        public int T_Target { get; set; }

        public int UT_Finished { get; set; }

        public int UT_Target { get; set; }

        public int M_Target { get; set; }
    }

    public class LeanDailyCapacity
    {
        public string? Date { get; set; }

        public int Finished { get; set; }

        public int Target { get; set; }
    }
}
