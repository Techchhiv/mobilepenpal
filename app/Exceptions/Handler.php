<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * A list of exception types with their corresponding custom log levels.
     *
     * @var array<class-string<\Throwable>, \Psr\Log\LogLevel::*>
     */
    protected $levels = [
        //
    ];

    /**
     * A list of the exception types that are not reported.
     *
     * @var array<int, class-string<\Throwable>>
     */
    protected $dontReport = [
        //
    ];

    /**
     * A list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     *
     * @return void
     */
    public function register()
    {
        // Validation errors
        $this->renderable(function (ValidationException $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                return response()->json([
                    'code' => 400,
                    'message' => __('messages.validation_error'),
                    'data' => null,
                    'error' => $e->errors()
                ], 400);
            }
        });

        // Not Found (URL not existing)
        $this->renderable(function (NotFoundHttpException $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                return response()->json([
                    'code' => 404,
                    'message' => __('messages.not_found'),
                    'data' => null,
                    'error' => []
                ], 404);
            }
        });

        // Model not found
        $this->renderable(function (ModelNotFoundException $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                return response()->json([
                    'code' => 404,
                    'message' => __('messages.not_found'),
                    'data' => null,
                    'error' => []
                ], 404);
            }
        });

        // Authorization (no permission)
        $this->renderable(function (AuthorizationException $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                return response()->json([
                    'code' => 403,
                    'message' => __('messages.unauthorized'),
                    'data' => null,
                    'error' => null
                ], 403);
            }
        });

        // Authentication (not logged in)
        $this->renderable(function (AuthenticationException $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                return response()->json([
                    'code' => 401,
                    'message' => __('messages.unauthenticated'),
                    'data' => null,
                    'error' => null
                ], 401);
            }
        });

        // General HTTP errors
        $this->renderable(function (HttpException $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                $code = $e->getStatusCode();
                $message = Response::$statusTexts[$code] ?? 'Error';
                return response()->json([
                    'code' => $code,
                    'message' => __('messages.an_error_occurred'),
                    'data' => null,
                    'error' => $message
                ], $code);
            }
        });

        // Catch-all fallback
        $this->renderable(function (Throwable $e, Request $request) {
            if ($request->is(['api/mobile/*', 'api/teacher/*', 'api/*'])) {
                return response()->json([
                    'code' => 500,
                    'message' => __('messages.an_error_occurred'),
                    'data' => null,
                    'error' => $e->getMessage()
                ], 500);
            }
        });
    }
}
