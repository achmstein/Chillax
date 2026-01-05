using System.Diagnostics.CodeAnalysis;
using Chillax.Basket.API.Repositories;
using Chillax.Basket.API.Extensions;
using ModelBasketItem = Chillax.Basket.API.Model.BasketItem;
using ModelBasketItemCustomization = Chillax.Basket.API.Model.BasketItemCustomization;
using ModelCustomerBasket = Chillax.Basket.API.Model.CustomerBasket;

namespace Chillax.Basket.API.Grpc;

public class BasketService(
    IBasketRepository repository,
    ILogger<BasketService> logger) : Basket.BasketBase
{
    [AllowAnonymous]
    public override async Task<CustomerBasketResponse> GetBasket(GetBasketRequest request, ServerCallContext context)
    {
        var userId = context.GetUserIdentity();
        if (string.IsNullOrEmpty(userId))
        {
            return new();
        }

        if (logger.IsEnabled(LogLevel.Debug))
        {
            logger.LogDebug("Begin GetBasketById call from method {Method} for basket id {Id}", context.Method, userId);
        }

        var data = await repository.GetBasketAsync(userId);

        if (data is not null)
        {
            return MapToCustomerBasketResponse(data);
        }

        return new();
    }

    public override async Task<CustomerBasketResponse> UpdateBasket(UpdateBasketRequest request, ServerCallContext context)
    {
        var userId = context.GetUserIdentity();
        if (string.IsNullOrEmpty(userId))
        {
            ThrowNotAuthenticated();
        }

        if (logger.IsEnabled(LogLevel.Debug))
        {
            logger.LogDebug("Begin UpdateBasket call from method {Method} for basket id {Id}", context.Method, userId);
        }

        var customerBasket = MapToCustomerBasket(userId, request);
        var response = await repository.UpdateBasketAsync(customerBasket);
        if (response is null)
        {
            ThrowBasketDoesNotExist(userId);
        }

        return MapToCustomerBasketResponse(response);
    }

    public override async Task<DeleteBasketResponse> DeleteBasket(DeleteBasketRequest request, ServerCallContext context)
    {
        var userId = context.GetUserIdentity();
        if (string.IsNullOrEmpty(userId))
        {
            ThrowNotAuthenticated();
        }

        await repository.DeleteBasketAsync(userId);
        return new();
    }

    [DoesNotReturn]
    private static void ThrowNotAuthenticated() => throw new RpcException(new Status(StatusCode.Unauthenticated, "The caller is not authenticated."));

    [DoesNotReturn]
    private static void ThrowBasketDoesNotExist(string userId) => throw new RpcException(new Status(StatusCode.NotFound, $"Basket with buyer id {userId} does not exist"));

    private static CustomerBasketResponse MapToCustomerBasketResponse(ModelCustomerBasket customerBasket)
    {
        var response = new CustomerBasketResponse();

        foreach (var item in customerBasket.Items)
        {
            var grpcItem = new BasketItem()
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                SpecialInstructions = item.SpecialInstructions ?? string.Empty
            };

            // Map customizations
            foreach (var customization in item.SelectedCustomizations)
            {
                grpcItem.SelectedCustomizations.Add(new BasketItemCustomization
                {
                    CustomizationId = customization.CustomizationId,
                    CustomizationName = customization.CustomizationName,
                    OptionId = customization.OptionId,
                    OptionName = customization.OptionName,
                    PriceAdjustment = (double)customization.PriceAdjustment
                });
            }

            response.Items.Add(grpcItem);
        }

        return response;
    }

    private static ModelCustomerBasket MapToCustomerBasket(string userId, UpdateBasketRequest customerBasketRequest)
    {
        var response = new ModelCustomerBasket
        {
            BuyerId = userId
        };

        foreach (var item in customerBasketRequest.Items)
        {
            var modelItem = new ModelBasketItem
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                SpecialInstructions = string.IsNullOrEmpty(item.SpecialInstructions) ? null : item.SpecialInstructions
            };

            // Map customizations
            foreach (var customization in item.SelectedCustomizations)
            {
                modelItem.SelectedCustomizations.Add(new ModelBasketItemCustomization
                {
                    CustomizationId = customization.CustomizationId,
                    CustomizationName = customization.CustomizationName,
                    OptionId = customization.OptionId,
                    OptionName = customization.OptionName,
                    PriceAdjustment = (decimal)customization.PriceAdjustment
                });
            }

            response.Items.Add(modelItem);
        }

        return response;
    }
}
