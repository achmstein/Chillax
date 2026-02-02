using Chillax.Notification.API.Model;

namespace Chillax.Notification.API.Localization;

/// <summary>
/// Localized notification messages for FCM notifications.
/// Arabic translations use Egyptian dialect.
/// </summary>
public static class NotificationMessages
{
    // Room Available
    public static readonly LocalizedText RoomAvailableTitle = new("Room Available!", "أوضة فاضية!");
    public static LocalizedText RoomAvailableBody(LocalizedText roomName, string lang) =>
        new($"{roomName.GetText("en")} is now available. Book now!",
            $"{roomName.GetText("ar")} فاضية دلوقتي. احجز دلوقتي!");

    // New Reservation
    public static readonly LocalizedText NewReservationTitle = new("New Reservation!", "حجز جديد!");
    public static LocalizedText NewReservationBody(string customerName, LocalizedText roomName, string lang) =>
        new($"{customerName} reserved {roomName.GetText("en")}",
            $"{customerName} حجز {roomName.GetText("ar")}");

    // New Order
    public static readonly LocalizedText NewOrderTitle = new("New Order!", "أوردر جديد!");
    public static LocalizedText NewOrderBody(int orderId, string buyerName) =>
        new($"Order #{orderId} from {buyerName}",
            $"أوردر #{orderId} من {buyerName}");

    // Service Requests
    public static readonly LocalizedText WaiterNeededTitle = new("Waiter Needed", "محتاج جرسون");
    public static LocalizedText WaiterNeededBody(LocalizedText roomName, string userName) =>
        new($"{roomName.GetText("en")} - {userName} is calling for a waiter",
            $"{roomName.GetText("ar")} - {userName} عايز جرسون");

    public static readonly LocalizedText ControllerRequestTitle = new("Controller Request", "عايز كنترولر تاني");
    public static LocalizedText ControllerRequestBody(LocalizedText roomName, string userName) =>
        new($"{roomName.GetText("en")} - {userName} needs a different controller",
            $"{roomName.GetText("ar")} - {userName} عايز كنترولر تاني");

    public static readonly LocalizedText BillRequestedTitle = new("Bill Requested", "عايز الحساب");
    public static LocalizedText BillRequestedBody(LocalizedText roomName, string userName) =>
        new($"{roomName.GetText("en")} - {userName} wants to pay",
            $"{roomName.GetText("ar")} - {userName} عايز يدفع");

    public static readonly LocalizedText ServiceRequestTitle = new("Service Request", "محتاج مساعدة");
    public static LocalizedText ServiceRequestBody(LocalizedText roomName, string userName) =>
        new($"{roomName.GetText("en")} - {userName} needs assistance",
            $"{roomName.GetText("ar")} - {userName} محتاج مساعدة");
}
