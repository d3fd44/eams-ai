#include <curl/curl.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#define NUM_THREADS 5
#define TARGET_URL  "http://localhost:3000/log"

volatile sig_atomic_t keep_running = 1;

void handle_sigint(int sig)
{
    keep_running = 0;
    printf("\nSignal received. Stopping all threads...\n");
}

typedef struct
{
    int thread_id;
} thread_args_t;

float rand_float()
{
    return (float)rand() / (float)(RAND_MAX);
}

void *producer_routine(void *arg)
{
    thread_args_t *args = (thread_args_t *)arg;
    int            id = args->thread_id;
    free(args);

    CURL    *curl;
    CURLcode res;
    int      message_count = 0;
    char     json_payload[512];

    unsigned int seed = time(NULL) + id;

    curl = curl_easy_init();

    if (!curl)
    {
        fprintf(stderr, "Thread %d failed to init curl\n", id);
        return NULL;
    }

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");

    curl_easy_setopt(curl, CURLOPT_URL, TARGET_URL);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    while (keep_running)
    {
        message_count++;

        snprintf(json_payload, sizeof(json_payload),
                 "{\"message\": {\"emp_id\": %d, \"features\": [%d, %.2f, %.2f, %.2f, %.2f, %.2f, "
                 "%.2f, %.2f]}, "
                 "\"key\": \"thread_%d\"}",
                 id, rand_r(&seed) % 20, rand_float(), rand_float(), rand_float(),
                 rand_float() * 0.5, rand_float() * 0.5, rand_float() * 0.2, rand_float() * 0.2,
                 id);

        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_payload);

        res = curl_easy_perform(curl);

        if (res != CURLE_OK)
        {
            fprintf(stderr, "[Thread %d] Failed: %s\n", id, curl_easy_strerror(res));
        }
        else
        {
            printf("[Thread %d] Sent msg %d\n", id, message_count);
        }

        sleep(1 + (rand_r(&seed) % 2));
    }

    printf("[Thread %d] Cleaning up.\n", id);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

    return NULL;
}

int main(int argc, char *argv[])
{
    pthread_t threads[NUM_THREADS];

    signal(SIGINT, handle_sigint);

    curl_global_init(CURL_GLOBAL_ALL);
    srand(time(NULL));  // Seed global random

    printf("Starting %d threads. Press Ctrl+C to stop.\n", NUM_THREADS);

    for (int i = 0; i < NUM_THREADS; i++)
    {
        thread_args_t *args = malloc(sizeof(thread_args_t));
        args->thread_id = i + 1;

        if (pthread_create(&threads[i], NULL, producer_routine, args) != 0)
        {
            perror("Failed to create thread");
            return 1;
        }
    }

    for (int i = 0; i < NUM_THREADS; i++)
    {
        pthread_join(threads[i], NULL);
    }

    curl_global_cleanup();
    printf("All threads stopped.\n");

    return 0;
}
