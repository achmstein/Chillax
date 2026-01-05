using System.Text.Json.Serialization;

namespace Chillax.Ordering.Domain.AggregatesModel.OrderAggregate;

/// <summary>
/// Simple order status for cafe orders.
/// Submitted -> Confirmed (then goes to POS) or Cancelled
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum OrderStatus
{
    Submitted = 1,
    Confirmed = 2,
    Cancelled = 3
}
