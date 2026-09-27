---
paths:
  - "tests/**/*.cs"
---
# Testing Rules

Test projects live under `tests/<Area>/*` (e.g. `Application.UnitTest`, `Domain.UnitTest`,
`ArchitectureTest`, `FunctionalTest`). Check `Directory.Build.props`/`*.csproj` for the target
framework these projects use.

## 1. Frameworks & Tooling

- **Test runner:** xUnit.
- **Assertions:** FluentAssertions exclusively (`result.Should().Be(...)`). Never raw `Assert.*`.
- **Mocking:** NSubstitute preferred (`Substitute.For<IOrderRepository>()`); Moq acceptable if a file already uses it — match the existing library in the project.
- **UI components** (if a component framework like Blazor is in use): bUnit.
- **Architecture:** keep/extend `ArchitectureTest` to enforce layer boundaries and naming.

## 2. Structure — AAA

Every test follows **Arrange → Act → Assert**, separated by blank lines:

```csharp
[Fact]
public async Task Handle_OrderDoesNotExist_ReturnsNotFoundError()
{
    // Arrange
    var repository = Substitute.For<IOrderRepository>();
    repository.GetByIdAsync(1, Arg.Any<CancellationToken>()).Returns((OrderEntity?)null);
    var sut = new GetOrderByIdQueryHandler(Substitute.For<IMapper>(), repository);

    // Act
    var result = await sut.Handle(new GetOrderByIdQuery(1), CancellationToken.None);

    // Assert
    result.IsSuccess.Should().BeFalse();
    result.ErrorCode.Should().Be(ProcessErrorCode.OrderNotFound);
}
```

## 3. Naming

`MethodName_StateUnderTest_ExpectedBehavior` — e.g. `Handle_ValidCommand_PersistsOrder`,
`Create_EmptyName_Throws`.

## 4. Unit Test Scope

- One logical assertion target per test (use FluentAssertions chaining, not many unrelated asserts).
- Test handlers in isolation: mock every injected dependency (repositories, `IUnitOfWork`, `IMapper`).
- **Domain entities:** test factory guards and behavior methods directly — no mocks needed (pure domain).
- Verify `Result<T>` outcomes (`IsSuccess`, `ErrorCode`, `Data`) AND key side effects (`repository.Received(1).Create(...)`, `unitOfWork.Received(1).SaveChangesAsync(...)`).
- Always pass `CancellationToken.None` (or a token) explicitly to match async signatures.

## 5. Integration Tests (EF Core)

- Use the EF Core in-memory provider or SQLite in-memory for repository/`DbContext` tests; never hit a real database.
- Seed via domain factory methods, not by mutating private state.
- Assert tracking behavior expectations (reads use `AsNoTracking`).

## 6. Component Tests (bUnit, if applicable)

- Use `TestContext`; register fakes for injected services (`Services.AddSingleton(Substitute.For<ISender>())`).
- Render with `RenderComponent<TComponent>(p => p.Add(c => c.Param, value))`.
- Assert on rendered markup (`cut.Find("...")`, `cut.Markup`) and on `EventCallback` invocations.
- Trigger lifecycle/UI events via bUnit (`cut.Find("button").Click()`); do not call private methods via reflection.

## 7. Quality Bar

- Tests must be deterministic — no real time, network, or `DateTime.Now` (inject a clock or assert ranges).
- No logic in tests (no loops/conditionals deciding assertions). Prefer `[Theory]` + `[InlineData]` for variations.
- Keep tests fast and independent; no shared mutable state between tests.
- Run `dotnet test` before finishing a task that touches production code.

## NSubstitute Cheatsheet

- Create: `Substitute.For<IX>()`
- Return: `sub.Method(arg).Returns(value)`; async: `.Returns(Task.FromResult(value))` or just the value.
- Args: `Arg.Any<T>()`, `Arg.Is<T>(x => x.Id == 1)`.
- Verify: `sub.Received(1).Method(...)`, `sub.DidNotReceive().Method(...)`.

See `.claude/skills/database-optimizer/SKILL.md` for EF/Dapper performance concerns that show up
in integration tests, and `.claude/rules/architecture.md` for the layer boundaries under test.
