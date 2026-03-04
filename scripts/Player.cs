using Godot;

public partial class Player : CharacterBody3D
{
	// ===== MOVEMENT SETTINGS =====
	[Export] public float WalkSpeed = 5f;
	[Export] public float SprintSpeed = 8f;
	[Export] public float CrouchSpeed = 3f;
	[Export] public float JumpVelocity = 4.5f;
	[Export] public float MouseSensitivity = 0.002f;
	[Export] public float Gravity = 9.8f;

	// ===== HEAD BOB SETTINGS =====
	[Export] public float BobFrequency = 8f;
	[Export] public float BobAmplitude = 0.05f;

	private Node3D head;
	private Camera3D camera;
	private RayCast3D ray;

	private CanvasLayer uiLayer;
	private Control crosshair;

	private float currentSpeed;
	private float bobTime = 0f;

	// Capsule total height = 1.8
	// Center is 0
	// So eye level slightly above center feels correct
	private float standingHeight = 0.45f;
	private float crouchHeight = 0.1f;

	private bool isPaused = false;

	public override void _Ready()
	{
		head = GetNode<Node3D>("Head");
		camera = head.GetNode<Camera3D>("Camera3D");
		ray = head.GetNode<RayCast3D>("RayCast3D");
		crosshair = GetNode<Control>("UI/Crosshair");

		Input.MouseMode = Input.MouseModeEnum.Captured;
	}

	public override void _Input(InputEvent @event)
	{
		// ===== ESC TOGGLE PAUSE =====
		if (@event.IsActionPressed("ui_cancel"))
		{
			TogglePause();
		}

		if (isPaused)
			return;

		if (@event is InputEventMouseMotion mouseMotion)
		{
			RotateY(-mouseMotion.Relative.X * MouseSensitivity);
			head.RotateX(-mouseMotion.Relative.Y * MouseSensitivity);

			Vector3 headRot = head.Rotation;
			headRot.X = Mathf.Clamp(headRot.X, Mathf.DegToRad(-89), Mathf.DegToRad(89));
			head.Rotation = headRot;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		if (isPaused)
			return;

		float d = (float)delta;
		Vector3 velocity = Velocity;

		// ===== GRAVITY =====
		if (!IsOnFloor())
			velocity.Y -= Gravity * d;

		// ===== JUMP =====
		if (Input.IsActionJustPressed("jump") && IsOnFloor())
			velocity.Y = JumpVelocity;

		// ===== SPEED STATES =====
		if (Input.IsActionPressed("crouch"))
			currentSpeed = CrouchSpeed;
		else if (Input.IsActionPressed("sprint"))
			currentSpeed = SprintSpeed;
		else
			currentSpeed = WalkSpeed;

		// ===== MOVEMENT INPUT =====
		Vector2 inputDir = Input.GetVector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward"
		);

		Vector3 direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

		if (direction != Vector3.Zero)
		{
			velocity.X = direction.X * currentSpeed;
			velocity.Z = direction.Z * currentSpeed;

			HandleHeadBob(d);
		}
		else
		{
			velocity.X = Mathf.MoveToward(Velocity.X, 0, currentSpeed);
			velocity.Z = Mathf.MoveToward(Velocity.Z, 0, currentSpeed);

			ResetHeadBob(d);
		}

		// ===== CROUCH HEIGHT SMOOTH =====
		float targetHeight = Input.IsActionPressed("crouch") ? crouchHeight : standingHeight;

		head.Position = new Vector3(
			0,
			Mathf.Lerp(head.Position.Y, targetHeight, d * 8f),
			0
		);

		Velocity = velocity;
		MoveAndSlide();

		// ===== INTERACT =====
		if (Input.IsActionJustPressed("interact"))
		{
			if (ray.IsColliding())
			{
				var collider = ray.GetCollider();
				if (collider != null && collider.HasMethod("Interact"))
				{
					collider.Call("Interact");
				}
			}
		}
	}

	// ===== HEAD BOB =====
	private void HandleHeadBob(float delta)
	{
		bobTime += delta * BobFrequency;
		float bobOffset = Mathf.Sin(bobTime) * BobAmplitude;

		camera.Position = new Vector3(
			0,
			bobOffset,
			0
		);
	}

	private void ResetHeadBob(float delta)
	{
		bobTime = 0f;

		camera.Position = new Vector3(
			0,
			Mathf.Lerp(camera.Position.Y, 0, delta * 5f),
			0
		);
	}

	private void TogglePause()
	{
		isPaused = !isPaused;
		GetTree().Paused = isPaused;

		if (isPaused)
		{
			Input.MouseMode = Input.MouseModeEnum.Visible;
			crosshair.Visible = false;
		}
		else
		{
			Input.MouseMode = Input.MouseModeEnum.Captured;
			crosshair.Visible = true;
		}
	}
}
