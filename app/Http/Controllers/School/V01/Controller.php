<?php

namespace App\Http\Controllers\School\V01;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

abstract class Controller
{
    use AuthorizesRequests, ValidatesRequests;

    protected string $entity_name = '';
    protected string $entity_name_plural = '';
    protected ?string $model = null;
    protected ?string $resource = null;
    protected ?string $request = null;
    protected array $fields = [];

    protected array $_errors = [];
    protected int $_code = 200;
    protected string $_message = 'OK';
    protected $_result = null;

    public function __construct()
    {
        $this->setup();
    }

    /**
     * Define setup logic in child controllers if needed.
     */
    protected function setup(): void
    {
        // You can override this in your child controller
    }

    // --- CONFIG SETTERS ---
    public function setValidation(string $class): void
    {
        $this->request = $class;
    }
    public function setResource(string $resource): void
    {
        $this->resource = $resource;
    }
    public function setModel(string $model): void
    {
        $this->model = $model;
    }
    public function setFields(array $fields): void
    {
        $this->fields = $fields;
    }
    public function setEntityNameStrings(string $singular, string $plural): void
    {
        $this->entity_name = $singular;
        $this->entity_name_plural = $plural;
    }

    // --- ERRORS ---
    public function getErrors(): array
    {
        return $this->_errors;
    }
    public function setError(mixed $errors): void
    {
        $this->_errors[] = $errors;
    }

    // --- CODE ---
    public function getCode(): int
    {
        return $this->_code;
    }
    public function setCode(int $code): void
    {
        $this->_code = $code;
    }

    // --- MESSAGE ---
    public function getMessage(): string
    {
        return $this->_message;
    }
    public function setMessage(string $msg): void
    {
        $this->_message = $msg;
    }

    // --- RESULT ---
    public function getResult(?string $name = null): mixed
    {
        if (!$name) return $this->_result;
        return $this->_result[$name] ?? null;
    }

    public function setResult(string $name, mixed $value): void
    {
        if (!empty($name)) $this->_result[$name] = $value;
    }

    /**
     * Return a standardized error response.
     */
    public function returnError(array|string $errors, int $code = 400): JsonResponse
    {
        $errorMsg = is_array($errors)
            ? collect($errors)->flatten()->first()
            : $errors;

        $this->setCode($code);
        $this->setMessage($errorMsg);
        $this->setError($errors);

        return $this->returnResponse($code);
    }

    /**
     * Return a standardized success response.
     */
    public function returnSuccess(string $message = 'OK', array $data = [], int $code = 200): JsonResponse
    {
        $this->setCode($code);
        $this->setMessage($message);
        $this->_result = $data == [] ? null : $data;

        return $this->returnResponse($code);
    }

    /**
     * Return a JSON response with consistent structure.
     */
    protected function returnResponse(int $httpCode = 200): JsonResponse
    {
        return response()->json([
            'code' => $this->getCode(),
            'message' => __($this->getMessage()),
            'data' => $this->getResult(),
            'errors' => $this->getErrors(),
            'timestamp' => Carbon::now()->toDateTimeString(),
        ], $httpCode);
    }
}
