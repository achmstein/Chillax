global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Threading;
global using System.Threading.Tasks;
global using MediatR;
global using Microsoft.AspNetCore.Mvc;
global using Chillax.Ordering.API.Application.Commands;
global using Chillax.Ordering.API.Application.Models;
global using Chillax.Ordering.API.Infrastructure.Services;
global using Chillax.Ordering.Domain.AggregatesModel.BuyerAggregate;
global using Chillax.Ordering.Domain.Events;
global using Chillax.Ordering.Domain.Exceptions;
global using Chillax.Ordering.Domain.SeedWork;
global using Chillax.Ordering.Infrastructure.Idempotency;
global using Microsoft.Extensions.Logging;
global using NSubstitute;
global using Chillax.Ordering.UnitTests;
global using Microsoft.VisualStudio.TestTools.UnitTesting;

[assembly: Parallelize(Workers = 0, Scope = ExecutionScope.MethodLevel)]
